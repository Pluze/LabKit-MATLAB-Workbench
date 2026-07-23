function steps = labkitValidationPlanForChangedPaths(root, changedPaths, varargin)
%LABKITVALIDATIONPLANFORCHANGEDPATHS Map changed files to runner selections.
% Expected caller: tests/runLabKitTests.m and runner guardrail tests.
% Inputs:
%   root         repository root used to check app GUI test folders
%   changedPaths relative repository paths from git diff or ls-files
%   Mode         conservative (default) or fast
% Output:
%   steps        struct array with RunNameSuffix, Suites, Tests, IncludeGui,
%                and Reason
% Side effects: none. Unknown paths intentionally fall back to the full
%   non-GUI runner selection rather than returning a narrow false signal.

    parseMode(varargin{:});
    changedPaths = normalizeChangedPaths(changedPaths);
    steps = emptyPlanSteps();
    for k = 1:numel(changedPaths)
        steps = [steps, stepsForChangedPath(root, changedPaths(k))];
    end
    % Keep every semantically requested route. The runner resolves the
    % selections to canonical test identities before execution, so a broad
    % route cannot suppress a narrower one because folder selectors overlap.
    steps = uniquePlanSteps(steps);
end

function steps = stepsForChangedPath(root, path)
    parts = split(path, "/").';
    steps = emptyPlanSteps();
    if isempty(parts)
        return;
    end

    first = parts(1);
    if path == "labkit_launcher.m"
        steps = [ ...
            planStep("project", "project", false, ...
            "Tests", launcherProjectTests(), ...
            "Reason", "launcher entrypoint change needs project guardrails"), ...
            planStep("gui_project_launcher", "gui/project/launcher", true, ...
            "Reason", "launcher entrypoint change needs launcher GUI coverage")];
    elseif path == "buildfile.m"
        steps = planStep("project_build", "project/build", false, ...
            "Reason", "build task change needs runner/build contracts");
    elseif path == "README.md"
        steps = planStep("project_docs", "project/docs", false, ...
            "Reason", "README change needs documentation guardrails");
    elseif endsWith(path, "AGENTS.md") || first == ".agents"
        steps = planStep("project_docs", "project/docs", false, ...
            "Reason", "repository or agent guidance changed");
    elseif first == "+labkit"
        steps = labkitPackageSteps(root, parts);
    elseif first == "apps"
        steps = appSourceSteps(root, parts);
    elseif first == "tests"
        steps = testPathSteps(root, parts);
    elseif first == "docs" || first == "site"
        steps = docPathSteps(parts);
    elseif first == "tools"
        steps = toolPathSteps(parts);
    elseif first == ".github"
        steps = githubPathSteps(parts);
    else
        steps = fullNonGuiStep();
    end
end

function steps = githubPathSteps(parts)
    if numel(parts) >= 2 && ismember(parts(2), ["workflows", "scripts"])
        steps = planStep("project_ci", "project/ci", false, ...
            "Reason", "GitHub workflow or CI helper changed");
    else
        steps = planStep("project_docs", "project/docs", false, ...
            "Reason", "GitHub contribution template changed");
    end
end

function steps = labkitPackageSteps(root, parts)
    if numel(parts) < 2
        steps = [ ...
            planStep("labkit_framework", "labkit_framework", true, ...
            "Reason", "broad +labkit framework change needs reusable coverage"), ...
            planStep("gui_apps", "gui/apps", true, ...
            "Reason", "broad +labkit framework change can affect app GUI contracts")];
        return;
    end

    packageName = erase(parts(2), "+");
    switch packageName
        case "app"
            steps = [ ...
                planStep("labkit_framework_ui", "labkit_framework/ui", false, ...
                "Reason", "labkit.app change needs reusable App SDK coverage"), ...
                planStep("gui_labkit_framework_ui", "gui/labkit_framework/ui", true, ...
                "Tests", [uiRepresentativeTests(), uiGestureRepresentativeTests()], ...
                "Reason", "labkit.app change needs representative UI GUI coverage"), ...
                allAppContractStep(root), ...
                allAppSmokeStep(root)];
        case {"dta", "rhs", "biosignal", "image", "thermal"}
            steps = leafFacadeSteps(root, packageName);
        otherwise
            steps = [ ...
                planStep("labkit_framework", "labkit_framework", true, ...
                "Reason", "+labkit framework package change needs reusable coverage"), ...
                planStep("gui_apps", "gui/apps", true, ...
                "Reason", "+labkit framework package change can affect app GUI contracts")];
    end
end

function step = allAppContractStep(root)
    step = planStep("apps_app_contracts", "unit/apps", false, ...
        "Tests", appOwnerTestNames(root, "unit", "appContract"), ...
        "Reason", "universal App SDK change needs every App public contract");
end

function step = allAppSmokeStep(root)
    [tests, fallback] = labkitAppSmokeFeatureTests(root, "app-layout");
    reason = "universal App SDK change needs the minimum smoke feature closure";
    if fallback
        reason = reason + "; missing route-feature metadata selects every App smoke";
    end
    step = planStep("gui_apps_smoke", "gui/apps", true, ...
        "Tests", tests, ...
        "Reason", reason);
end

function names = appOwnerTestNames(root, kind, scope)
    entries = dir(fullfile(root, "tests", "cases", kind, "apps", ...
        "**", scope, "*Test.m"));
    names = strings(1, numel(entries));
    for k = 1:numel(entries)
        [~, names(k)] = fileparts(entries(k).name);
    end
    names = unique(names, "stable");
end

function steps = leafFacadeSteps(root, area)
    area = string(area);
    steps = planStep("labkit_framework_" + area, ...
        "labkit_framework/" + area, false, ...
        "Reason", "leaf facade change needs its direct framework coverage");
    consumers = facadeConsumers(root, area);
    for k = 1:numel(consumers)
        family = consumers(k).family;
        slug = consumers(k).slug;
        scope = consumers(k).scope;
        unitTarget = appExactTestSuiteTarget(root, "unit", family, slug, scope);
        if ~isempty(unitTarget)
            steps(end + 1) = planStep(suiteRunNameSuffix(unitTarget), ...
                unitTarget, false, ...
                "Reason", "leaf facade change reaches a direct App capability consumer");
        end
        contractTarget = appExactTestSuiteTarget( ...
            root, "contract", family, slug, "isolatedPath");
        if ~isempty(contractTarget)
            steps(end + 1) = planStep(suiteRunNameSuffix(contractTarget), ...
                contractTarget, false, ...
                "Reason", "leaf facade change keeps each direct consumer isolated");
        end
        smokeTarget = appExactTestSuiteTarget(root, "gui", family, slug, "smoke");
        if ~isempty(smokeTarget)
            steps(end + 1) = planStep(suiteRunNameSuffix(smokeTarget), ...
                smokeTarget, true, ...
                "Reason", "leaf facade change keeps each direct consumer smoke proof");
        end
    end
end

function consumers = facadeConsumers(root, area)
    files = dir(fullfile(root, "apps", "**", "*.m"));
    consumers = repmat(struct("family", "", "slug", "", "scope", ""), 1, 0);
    marker = "labkit." + string(area) + ".";
    appsRoot = string(fullfile(root, "apps")) + filesep;
    for k = 1:numel(files)
        filePath = string(fullfile(files(k).folder, files(k).name));
        if ~contains(string(fileread(filePath)), marker)
            continue;
        end
        relative = extractAfter(filePath, strlength(appsRoot));
        pieces = split(replace(relative, filesep, "/"), "/");
        if numel(pieces) < 4 || ~startsWith(pieces(3), "+")
            continue;
        end
        scope = "appContract";
        if numel(pieces) >= 4 && startsWith(pieces(4), "+")
            scope = erase(pieces(4), "+");
        end
        candidate = struct("family", pieces(1), "slug", pieces(2), ...
            "scope", scope);
        if ~any(arrayfun(@(item) item.family == candidate.family && ...
                item.slug == candidate.slug && item.scope == candidate.scope, consumers))
            consumers(end + 1) = candidate;
        end
    end
end

function steps = appSourceSteps(root, parts)
    if numel(parts) < 2
        steps = [ ...
            planStep("unit_apps", "unit/apps", false, ...
            "Reason", "broad app source change needs app logic coverage"), ...
            planStep("gui_apps", "gui/apps", true, ...
            "Reason", "broad app source change can affect app GUI workflows"), ...
            planStep("apps_isolated_contract", "contract/apps", false, ...
            "Reason", "broad app source change needs every owned isolated-path contract")];
        return;
    end

    family = parts(2);
    slug = appSlug(parts);
    scope = appSourceScope(parts);
    isolationTarget = appExactTestSuiteTarget( ...
        root, "contract", family, slug, "isolatedPath");
    if isempty(isolationTarget)
        isolationStep = planStep("apps_isolated_contract", "contract/apps", false, ...
            "Reason", "app source change cannot resolve an owned isolated-path contract");
    else
        isolationStep = planStep(suiteRunNameSuffix(isolationTarget), ...
            isolationTarget, false, ...
            "Reason", "app source change keeps its owning isolated-path contract");
    end
    unitTarget = appTestSuiteTarget(root, "unit", family, slug, scope);
    steps = isolationStep;
    if ~isempty(unitTarget)
        steps = [planStep(suiteRunNameSuffix(unitTarget), unitTarget, false, ...
            "Reason", appSourceReason("unit", family, slug, scope, unitTarget)), ...
            steps];
    end
    guiTarget = appTestSuiteTarget(root, "gui", family, slug, scope);
    if ~isempty(guiTarget)
        steps = [steps, planStep(suiteRunNameSuffix(guiTarget), guiTarget, true, ...
            "Reason", appSourceReason("gui", family, slug, scope, guiTarget))];
    end
    smokeTarget = appExactTestSuiteTarget(root, "gui", family, slug, "smoke");
    if ~isempty(smokeTarget) && ~any(guiTarget == smokeTarget)
        steps = [steps, planStep(suiteRunNameSuffix(smokeTarget), smokeTarget, true, ...
            "Reason", "app source change keeps the owning App smoke proof")];
    end
end

function steps = testPathSteps(root, parts)
    if numel(parts) >= 4 && all(parts(1:2) == ["tests", "cases"]) && ...
            endsWith(parts(end), ".m")
        includeGui = parts(3) == "gui";
        steps = planStep("changed_test_file", strings(1, 0), includeGui, ...
            "Files", strjoin(parts, "/"), ...
            "Reason", "changed test file should rerun exactly itself");
    elseif numel(parts) >= 2 && parts(2) == "runLabKitTests.m"
        steps = planStep("project_build", "project/build", false, ...
            "Reason", "runner entrypoint change needs runner/build contracts");
    elseif numel(parts) >= 2 && parts(2) == "runner"
        steps = planStep("project_build", "project/build", false, ...
            "Reason", "runner implementation change needs runner/build contracts");
    elseif numel(parts) >= 2 && parts(2) == "shared"
        steps = sharedTestPathSteps(root, parts);
    else
        steps = planStep("project", "project", false, ...
            "Reason", "test support or policy file changed");
    end
end

function steps = docPathSteps(parts)
    tests = strings(1, 0);
    reason = "documentation change needs documentation guardrails";
    if parts(1) == "docs" && numel(parts) >= 2
        switch parts(2)
            case "apps"
                tests = [ ...
                    "AppDocumentationGuardrailTest", ...
                    "ProjectDocumentationGuardrailTest/markedAppManualExamplesExecute"];
                reason = "App documentation change needs App manual contracts";
            case "history"
                tests = [ ...
                    "DocumentationRendererRegressionTest/historyUsesOneTimelineForEveryEra", ...
                    "DocumentationRendererRegressionTest/historyRecordsLinkAdjacentSequenceAtPageEnd", ...
                    "ProjectDocumentationGuardrailTest/historyRecordsDoNotUseEmptyNormalizationBoilerplate"];
                reason = "history documentation change needs focused history contracts";
            case "libraries"
                tests = "LibraryDocumentationGuardrailTest";
                reason = "library documentation change needs library reference contracts";
        end
    end
    steps = planStep("project_docs", "project/docs", false, ...
        "Tests", tests, ...
        "Reason", reason);
end

function steps = toolPathSteps(parts)
    if numel(parts) >= 2 && parts(2) == "docs"
        steps = planStep("project_docs", "project/docs", false, ...
            "Reason", "documentation renderer change needs documentation guardrails");
    elseif numel(parts) >= 2 && parts(2) == "deployment"
        steps = planStep("project_package", "project", false, ...
            "Tests", "PackageLabKitAppToolTest", ...
            "Reason", "deployment tool change needs package tool coverage");
    elseif numel(parts) >= 2 && parts(2) == "profiling"
        steps = planStep("project_profile", "project", false, ...
            "Tests", "ProfileLabKitToolTest", ...
            "Reason", "profiling tool change needs profiler tool coverage");
    else
        steps = planStep("project", "project", false, ...
            "Reason", "maintainer tool change needs project guardrails");
    end
end

function steps = sharedTestPathSteps(root, parts)
    filename = "";
    if ~isempty(parts)
        filename = lower(parts(end));
    end
    consumers = sharedHelperConsumers(root, filename);
    if contains(filename, "launcher")
        steps = planStep("gui_project_launcher", "gui/project/launcher", true, ...
            "Reason", "shared launcher test helper changed");
    elseif ~isempty(consumers.guiTests) || ~isempty(consumers.nonGuiTests)
        steps = emptyPlanSteps();
        if ~isempty(consumers.nonGuiTests)
            steps(end + 1) = planStep("shared_consumers", strings(1, 0), false, ...
                "Tests", consumers.nonGuiTests, ...
                "Reason", "shared test helper change reruns direct non-GUI consumers");
        end
        if ~isempty(consumers.guiTests)
            steps(end + 1) = planStep("gui_shared_consumers", "gui", true, ...
                "Tests", consumers.guiTests, ...
                "Reason", "shared test helper change reruns direct GUI consumers");
        end
    elseif contains(filename, "gui") || contains(filename, "uispec") || ...
            contains(filename, "snapshot")
        steps = planStep("gui", "gui", true, ...
            "Reason", "shared GUI test helper changed");
    else
        steps = fullNonGuiStep();
    end
end

function consumers = sharedHelperConsumers(root, filename)
    consumers = struct( ...
        "guiTests", strings(1, 0), ...
        "nonGuiTests", strings(1, 0));
    [~, helperName] = fileparts(char(filename));
    if strlength(string(helperName)) == 0
        return;
    end
    casesRoot = fullfile(root, "tests", "cases");
    entries = dir(fullfile(casesRoot, "**", "*.m"));
    callPattern = ['(^|[^A-Za-z0-9_])' ...
        regexptranslate('escape', helperName) '\s*\('];
    for iFile = 1:numel(entries)
        filepath = fullfile(entries(iFile).folder, entries(iFile).name);
        source = fileread(filepath);
        if isempty(regexpi(source, callPattern, 'once'))
            continue;
        end
        selector = string(erase(entries(iFile).name, ".m"));
        relativePath = replace(string(filepath), "\", "/");
        if contains(relativePath, "/tests/cases/gui/")
            consumers.guiTests(end + 1) = selector;
        else
            consumers.nonGuiTests(end + 1) = selector;
        end
    end
    consumers.guiTests = unique(consumers.guiTests, "stable");
    consumers.nonGuiTests = unique(consumers.nonGuiTests, "stable");
end

function tests = launcherProjectTests()
    tests = [ ...
        "StartupBoundariesTest", ...
        "VersionChangeGuardrailTest", ...
        "DocumentationHistoryGuardrailTest", ...
        "RepositoryHygieneGuardrailTest", ...
        "PackageLabKitAppToolTest", ...
        "ProfileLabKitToolTest"];
end

function slug = appSlug(parts)
    if numel(parts) >= 3
        slug = parts(3);
    else
        slug = "";
    end
end

function target = appTestSuiteTarget(root, kind, family, slug, scope)
    kind = string(kind);
    family = string(family);
    slug = string(slug);
    scope = string(scope);

    if strlength(slug) == 0
        familyFolder = fullfile(root, "tests", "cases", kind, "apps", family);
        if exist(familyFolder, "dir") == 7
            target = kind + "/apps/" + family;
        else
            target = strings(1, 0);
        end
        return;
    end

    if strlength(scope) > 0
        scopeFolder = fullfile(root, "tests", "cases", kind, "apps", ...
            family, slug, scope);
        if exist(scopeFolder, "dir") == 7
            target = kind + "/apps/" + family + "/" + slug + "/" + scope;
            return;
        end
    end

    if ismember(kind, ["unit", "gui"])
        target = strings(1, 0);
        return;
    end

    appFolder = fullfile(root, "tests", "cases", kind, "apps", family, slug);
    if exist(appFolder, "dir") == 7
        target = kind + "/apps/" + family + "/" + slug;
        return;
    end

    appFamilyFolder = fullfile(root, "tests", "cases", kind, "apps", family);
    if exist(appFamilyFolder, "dir") == 7
        target = kind + "/apps/" + family;
    else
        target = strings(1, 0);
    end
end

function target = appExactTestSuiteTarget(root, kind, family, slug, scope)
    kind = string(kind);
    family = string(family);
    slug = string(slug);
    scope = string(scope);
    folder = fullfile(root, "tests", "cases", kind, "apps", ...
        family, slug, scope);
    if exist(folder, "dir") == 7
        target = kind + "/apps/" + family + "/" + slug + "/" + scope;
    else
        target = strings(1, 0);
    end
end

function scope = appSourceScope(parts)
    scope = "appContract";
    if numel(parts) < 5
        return;
    end

    candidate = string(parts(5));
    if candidate == "+workbench"
        scope = "workbench";
    elseif startsWith(candidate, "+")
        scope = erase(candidate, "+");
    end
end

function reason = appSourceReason(kind, family, slug, scope, target)
    reason = "app source change uses its deepest owning test scope";
end

function suffix = suiteRunNameSuffix(suite)
    suffix = safeRunNamePart(replace(string(suite), "/", "_"));
end

function value = safeRunNamePart(value)
    value = regexprep(char(string(value)), '[^A-Za-z0-9_]+', '_');
    value = string(value);
end

function step = fullNonGuiStep()
    step = planStep("headless", strings(1, 0), false, ...
        "Reason", "fallback needs full non-GUI coverage");
end

function step = planStep(runNameSuffix, suites, includeGui, varargin)
    tests = strings(1, 0);
    files = strings(1, 0);
    reason = "";
    if ~isempty(varargin)
        p = inputParser;
        p.FunctionName = "planStep";
        p.addParameter("Tests", tests, @isStringLikeList);
        p.addParameter("Files", files, @isStringLikeList);
        p.addParameter("Reason", reason, @isTextScalar);
        p.parse(varargin{:});
        tests = normalizeTextList(p.Results.Tests);
        files = normalizeTextList(p.Results.Files);
        reason = string(p.Results.Reason);
    end
    step = struct( ...
        "RunNameSuffix", string(runNameSuffix), ...
        "Suites", {normalizeTextList(suites)}, ...
        "Files", {files}, ...
        "Tests", {tests}, ...
        "IncludeGui", logical(includeGui), ...
        "Reason", reason);
end

function tests = uiRepresentativeTests()
    tests = [ ...
        "reconcilesChronoLikeSemanticTree", ...
        "nativeCallbacksUseTypedRuntimeEntrypoints", ...
        "replacesChoicesWhenCurrentValueDisappears"];
end

function tests = uiGestureRepresentativeTests()
    tests = "reconcilesManagedRectangleAndDispatchesDirectCallback";
end

function mode = parseMode(varargin)
    mode = "conservative";
    if isempty(varargin)
        return;
    end

    p = inputParser;
    p.FunctionName = "labkitValidationPlanForChangedPaths";
    p.addParameter("Mode", mode, @isTextScalar);
    p.parse(varargin{:});
    mode = lower(string(p.Results.Mode));
    if ~ismember(mode, ["conservative", "fast"])
        error("LabKit:Tests:InvalidValidationPlanMode", ...
            "Changed validation plan Mode must be conservative or fast.");
    end
end

function steps = emptyPlanSteps()
    steps = struct("RunNameSuffix", {}, "Suites", {}, "Files", {}, "Tests", {}, ...
        "IncludeGui", {}, "Reason", {});
end

function steps = uniquePlanSteps(steps)
    if isempty(steps)
        return;
    end

    keep = true(1, numel(steps));
    signatures = strings(1, numel(steps));
    for k = 1:numel(steps)
        signatures(k) = stepSignature(steps(k));
        keep(k) = ~any(signatures(1:k-1) == signatures(k));
    end
    steps = steps(keep);
end

function signature = stepSignature(step)
    signature = strjoin(step.Suites, ",") + "|" + ...
        strjoin(step.Files, ",") + "|" + strjoin(step.Tests, ",") + ...
        "|" + string(step.IncludeGui);
end

function paths = normalizeChangedPaths(paths)
    paths = normalizeTextList(paths);
    paths = strip(replace(paths, "\", "/"));
    paths = paths(strlength(paths) > 0);
    while any(startsWith(paths, "./"))
        paths = replace(paths, "./", "");
    end
end

function values = normalizeTextList(values)
    if isempty(values)
        values = strings(1, 0);
    elseif ischar(values)
        values = string({values});
    elseif iscell(values)
        values = string(values);
    else
        values = string(values);
    end
    values = values(:).';
    values = values(strlength(values) > 0);
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isStringLikeList(value)
    tf = ischar(value) || isstring(value) || iscellstr(value);
end
