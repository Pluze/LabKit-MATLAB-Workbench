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

    mode = parseMode(varargin{:});
    changedPaths = normalizeChangedPaths(changedPaths);
    steps = emptyPlanSteps();
    for k = 1:numel(changedPaths)
        steps = [steps, stepsForChangedPath(root, changedPaths(k))];
    end
    steps = compressPlanSteps(uniquePlanSteps(steps));
    if mode == "fast"
        steps = fastPlanSteps(steps);
    end
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
        steps = labkitPackageSteps(parts);
    elseif first == "apps"
        steps = appSourceSteps(root, parts);
    elseif first == "tests"
        steps = testPathSteps(root, parts);
    elseif first == "docs" || first == "site"
        steps = docPathSteps();
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

function steps = labkitPackageSteps(parts)
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
                planStep("labkit_framework_ui", "labkit_framework/ui", true, ...
                "Reason", "labkit.app change needs reusable App SDK coverage"), ...
                planStep("gui_apps", "gui/apps", true, ...
                "Reason", "labkit.app change can affect downstream app GUI contracts")];
        case "dta"
            steps = [ ...
                planStep("labkit_framework_dta", "labkit_framework/dta", false, ...
                "Reason", "labkit.dta change needs DTA facade coverage"), ...
                planStep("apps_electrochem", "apps/electrochem", false, ...
                "Reason", "DTA facade change can affect electrochem app logic"), ...
                planStep("gui_apps_electrochem", "gui/apps/electrochem", true, ...
                "Reason", "DTA facade change can affect electrochem GUI workflows")];
        case "rhs"
            steps = [ ...
                planStep("labkit_framework_rhs", "labkit_framework/rhs", false, ...
                "Reason", "labkit.rhs change needs RHS facade coverage"), ...
                planStep("apps_neurophysiology", "apps/neurophysiology", false, ...
                "Reason", "RHS facade change can affect neurophysiology app logic")];
        case "biosignal"
            steps = [ ...
                planStep("labkit_framework_biosignal", "labkit_framework/biosignal", false, ...
                "Reason", "labkit.biosignal change needs biosignal facade coverage"), ...
                planStep("apps_wearable", "apps/wearable", false, ...
                "Reason", "biosignal facade change can affect wearable app logic"), ...
                planStep("apps_neurophysiology", "apps/neurophysiology", false, ...
                "Reason", "biosignal facade change can affect neurophysiology app logic"), ...
                planStep("gui_apps_wearable", "gui/apps/wearable", true, ...
                "Reason", "biosignal facade change can affect wearable GUI workflows")];
        case "image"
            steps = [ ...
                planStep("labkit_framework_image", "labkit_framework/image", false, ...
                "Reason", "labkit.image change needs image facade coverage"), ...
                planStep("apps_image_measurement", "apps/image_measurement", false, ...
                "Reason", "image facade change can affect image-measurement app logic"), ...
                planStep("gui_apps_image_measurement", "gui/apps/image_measurement", true, ...
                "Reason", "image facade change can affect image-measurement GUI workflows")];
        case "thermal"
            steps = [ ...
                planStep("labkit_framework_thermal", "labkit_framework/thermal", false, ...
                "Reason", "labkit.thermal change needs thermal facade coverage"), ...
                planStep("apps_image_measurement", "apps/image_measurement", false, ...
                "Reason", "thermal facade change can affect image-measurement app logic"), ...
                planStep("gui_apps_image_measurement", "gui/apps/image_measurement", true, ...
                "Reason", "thermal facade change can affect image-measurement GUI workflows")];
        otherwise
            steps = [ ...
                planStep("labkit_framework", "labkit_framework", true, ...
                "Reason", "+labkit framework package change needs reusable coverage"), ...
                planStep("gui_apps", "gui/apps", true, ...
                "Reason", "+labkit framework package change can affect app GUI contracts")];
    end
end

function steps = appSourceSteps(root, parts)
    isolationStep = planStep("apps_isolated_contract", "contract/apps", false, ...
        "Tests", "publicAppsLoadContractsAndDebugSamplesOnOwningPath", ...
        "Reason", "app source change must remain runnable without sibling App paths");
    if numel(parts) < 2
        steps = [ ...
            planStep("unit_apps", "unit/apps", false, ...
            "Reason", "broad app source change needs app logic coverage"), ...
            planStep("gui_apps", "gui/apps", true, ...
            "Reason", "broad app source change can affect app GUI workflows"), ...
            isolationStep];
        return;
    end

    family = parts(2);
    slug = appSlug(parts);
    scope = appSourceScope(parts);
    unitTarget = appTestSuiteTarget(root, "unit", family, slug, scope);
    steps = [ ...
        planStep(suiteRunNameSuffix(unitTarget), unitTarget, false, ...
            "Reason", appSourceReason("unit", family, slug, scope, unitTarget)), ...
        isolationStep];
    guiTarget = appTestSuiteTarget(root, "gui", family, slug, scope);
    if strlength(guiTarget) > 0
        steps = [steps, planStep(suiteRunNameSuffix(guiTarget), guiTarget, true, ...
            "Reason", appSourceReason("gui", family, slug, scope, guiTarget))];
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

function steps = docPathSteps()
    steps = planStep("project_docs", "project/docs", false, ...
        "Reason", "human documentation changed");
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
    requested = string(kind) + "/apps/" + string(family) + "/" + ...
        string(slug) + "/" + string(scope);
    if string(target) == requested
        reason = "app source change uses its deepest owning test scope";
    else
        reason = "app source change uses a migration fallback from " + ...
            requested + " to " + string(target);
    end
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

function steps = fastPlanSteps(steps)
    fastSteps = emptyPlanSteps();
    for k = 1:numel(steps)
        fastSteps = [fastSteps, fastStepForPlanStep(steps(k))];
    end
    steps = compressPlanSteps(uniquePlanSteps(fastSteps));
end

function steps = fastStepForPlanStep(step)
    suites = normalizeTextList(step.Suites);
    if ~step.IncludeGui || isempty(suites)
        steps = step;
        return;
    end

    if any(suites == "labkit_framework/ui")
        steps = [ ...
            planStep("labkit_framework_ui", "labkit_framework/ui", false, ...
            "Reason", "fast UI route keeps reusable UI non-GUI coverage"), ...
            planStep("gui_labkit_framework_ui_representative", ...
            "gui/labkit_framework/ui", true, ...
            "Tests", [fastUiRepresentativeTests(), fastUiGestureRepresentativeTests()], ...
            "Reason", "fast UI route uses representative UI GUI and gesture contracts")];
    elseif any(suites == "gui")
        steps = planStep("gui_representative", ...
            ["gui/labkit_framework/ui", ...
            "gui/apps/image_measurement/image_enhance", ...
            "gui/apps/image_measurement/batch_crop"], true, ...
            "Tests", fastGuiRepresentativeTests(), ...
            "Reason", "fast GUI route uses representative UI and app workflows");
    elseif any(suites == "gui/apps")
        steps = planStep("gui_apps_representative", ...
            ["gui/apps/image_measurement/image_enhance", ...
            "gui/apps/image_measurement/batch_crop"], true, ...
            "Tests", fastRepresentativeAppGuiTests(), ...
            "Reason", "fast app-GUI route uses representative downstream workflows");
    else
        steps = step;
    end
end

function tests = fastGuiRepresentativeTests()
    tests = [ ...
        fastRepresentativeAppGuiTests(), ...
        fastUiRepresentativeTests(), ...
        fastUiGestureRepresentativeTests()];
end

function tests = fastRepresentativeAppGuiTests()
    tests = [ ...
        "image_enhance_workflow_applies_tool_and_exports", ...
        "cropTasksCenterAndExportSyntheticImages"];
end

function tests = fastUiRepresentativeTests()
    tests = [ ...
        "reconcilesChronoLikeSemanticTree", ...
        "nativeCallbacksUseTypedRuntimeEntrypoints", ...
        "replacesChoicesWhenCurrentValueDisappears"];
end

function tests = fastUiGestureRepresentativeTests()
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

function steps = compressPlanSteps(steps)
    if isempty(steps)
        return;
    end

    keep = true(1, numel(steps));
    for k = 1:numel(steps)
        for j = 1:numel(steps)
            if k == j || ~keep(k)
                continue;
            end
            if stepCovers(steps(j), steps(k))
                keep(k) = false;
            end
        end
    end
    steps = steps(keep);
end

function tf = stepCovers(candidate, step)
    if stepSignature(candidate) == stepSignature(step)
        tf = true;
        return;
    end

    if candidate.IncludeGui ~= step.IncludeGui
        tf = false;
        return;
    end
    if ~testsCover(candidate, step)
        tf = false;
        return;
    end
    if ~filesCover(candidate, step)
        tf = false;
        return;
    end

    candidateSuites = normalizeTextList(candidate.Suites);
    stepSuites = normalizeTextList(step.Suites);
    if isempty(stepSuites) && ~isempty(step.Files)
        tf = true;
        return;
    end
    if isempty(candidateSuites)
        tf = ~step.IncludeGui;
        return;
    end
    if isempty(stepSuites)
        tf = false;
        return;
    end

    tf = true;
    for k = 1:numel(stepSuites)
        tf = tf && suiteCoveredByAny(candidateSuites, stepSuites(k));
    end
end

function tf = filesCover(candidate, step)
    candidateFiles = normalizeTextList(candidate.Files);
    stepFiles = normalizeTextList(step.Files);
    if isempty(candidateFiles)
        if isempty(stepFiles)
            tf = true;
            return;
        end
        candidateSuites = normalizeTextList(candidate.Suites);
        if isempty(candidateSuites)
            tf = ~candidate.IncludeGui;
            return;
        end
        tf = all(arrayfun(@(file) fileCoveredBySuites( ...
            candidateSuites, file), stepFiles));
    elseif isempty(stepFiles)
        tf = false;
    else
        tf = all(ismember(stepFiles, candidateFiles));
    end
end

function tf = fileCoveredBySuites(suites, file)
    folder = replace(string(fileparts(char(file))), "\", "/");
    folder = eraseLeadingPrefix(folder, "tests/cases/");
    semanticFolder = folder;
    semanticFolder = eraseLeadingPrefix(semanticFolder, "unit/");
    semanticFolder = eraseLeadingPrefix(semanticFolder, "contract/");
    semanticFolder = eraseLeadingPrefix(semanticFolder, "gui/");
    tf = suiteCoveredByAny(suites, folder) || ...
        suiteCoveredByAny(suites, semanticFolder);
end

function value = eraseLeadingPrefix(value, prefix)
    if startsWith(value, prefix)
        value = extractAfter(value, strlength(prefix));
    end
end

function tf = testsCover(candidate, step)
    candidateTests = normalizeTextList(candidate.Tests);
    stepTests = normalizeTextList(step.Tests);
    if isempty(candidateTests)
        tf = true;
    elseif isempty(stepTests)
        tf = false;
    else
        tf = all(ismember(stepTests, candidateTests));
    end
end

function tf = suiteCoveredByAny(candidateSuites, target)
    tf = false;
    target = string(target);
    for k = 1:numel(candidateSuites)
        candidate = string(candidateSuites(k));
        tf = tf || target == candidate || startsWith(target, candidate + "/");
    end
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
