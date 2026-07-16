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
    elseif path == "README.md"
        steps = planStep("project_docs", "project/docs", false, ...
            "Reason", "README change needs documentation guardrails");
    elseif isProjectRoutingPath(path)
        steps = planStep("project", "project", false, ...
            "Reason", "project or validation-policy file changed");
    elseif first == "+labkit"
        steps = labkitPackageSteps(parts);
    elseif first == "apps"
        steps = appSourceSteps(root, parts);
    elseif first == "tests"
        steps = testPathSteps(root, parts);
    elseif first == "docs"
        steps = docPathSteps(parts);
    elseif first == "tools"
        steps = toolPathSteps(parts);
    elseif startsWith(first, ".github") || first == ".agents"
        steps = planStep("project", "project", false, ...
            "Reason", "agent docs or GitHub workflow changed");
    elseif isHeadlessRoutingPath(path)
        steps = fullNonGuiStep();
    else
        steps = fullNonGuiStep();
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
        case "ui"
            steps = [ ...
                planStep("labkit_framework_ui", "labkit_framework/ui", true, ...
                "Reason", "labkit.ui change needs reusable UI coverage"), ...
                planStep("gui_apps", "gui/apps", true, ...
                "Reason", "labkit.ui change can affect downstream app GUI contracts")];
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
    if numel(parts) < 2
        steps = [ ...
            planStep("apps", "apps", false, ...
            "Reason", "broad app source change needs app logic coverage"), ...
            planStep("gui_apps", "gui/apps", true, ...
            "Reason", "broad app source change can affect app GUI workflows")];
        return;
    end

    family = parts(2);
    steps = planStep("apps_" + safeRunNamePart(family), ...
        "apps/" + family, false, ...
        "Reason", "app source change needs owning app-family logic coverage");
    guiTarget = appGuiSuiteTarget(root, family, appSlug(parts));
    if strlength(guiTarget) > 0
        steps = [steps, planStep(suiteRunNameSuffix(guiTarget), guiTarget, true, ...
            "Reason", "app source change has matching GUI coverage")];
    end
end

function steps = testPathSteps(root, parts)
    if numel(parts) >= 4 && all(parts(1:3) == ["tests", "cases", "unit"])
        steps = unitTestPathSteps(parts);
    elseif numel(parts) >= 4 && all(parts(1:3) == ["tests", "cases", "gui"])
        steps = guiTestPathSteps(root, parts);
    elseif numel(parts) >= 6 && ...
            all(parts(1:4) == ["tests", "cases", "contract", "project"])
        area = parts(5);
        steps = planStep("project_" + safeRunNamePart(area), ...
            "project/" + area, false, ...
            "Tests", testFileSelector(parts), ...
            "Reason", "project contract test change should rerun the owning test");
    elseif numel(parts) >= 3 && all(parts(1:2) == ["tests", "cases"])
        steps = planStep("project", "project", false, ...
            "Reason", "contract test change needs project guardrails");
    elseif numel(parts) >= 2 && parts(2) == "runner"
        steps = fullNonGuiStep();
    elseif numel(parts) >= 2 && parts(2) == "shared"
        steps = sharedTestPathSteps(root, parts);
    else
        steps = planStep("project", "project", false, ...
            "Reason", "test support or policy file changed");
    end
end

function steps = unitTestPathSteps(parts)
    if numel(parts) >= 5 && parts(4) == "labkit_framework"
        area = parts(5);
        steps = planStep("labkit_framework_" + safeRunNamePart(area), ...
            "labkit_framework/" + area, false, ...
            "Reason", "LabKit framework unit test change should rerun the same area");
    elseif numel(parts) >= 5 && parts(4) == "apps"
        family = parts(5);
        steps = planStep("apps_" + safeRunNamePart(family), ...
            "apps/" + family, false, ...
            "Reason", "app unit test change should rerun the same family");
    elseif numel(parts) >= 4 && parts(4) == "project"
        steps = planStep("project", "project", false, ...
            "Tests", testFileSelector(parts), ...
            "Reason", "project unit test change should rerun the owning test");
    else
        steps = fullNonGuiStep();
    end
end

function steps = guiTestPathSteps(root, parts)
    if numel(parts) >= 6 && parts(4) == "apps"
        family = parts(5);
        slug = "";
        if numel(parts) >= 6
            slug = parts(6);
        end
        target = appGuiSuiteTarget(root, family, slug);
        steps = planStep(suiteRunNameSuffix(target), target, true, ...
            "Reason", "GUI test change should rerun the same GUI suite");
    elseif numel(parts) >= 5 && parts(4) == "labkit_framework"
        area = parts(5);
        if area == "ui"
            steps = planStep("gui_labkit_framework_ui", ...
                "gui/labkit_framework/ui", true, ...
                "Reason", "LabKit framework UI GUI test changed");
        else
            steps = planStep("gui_labkit_framework_" + safeRunNamePart(area), ...
                "gui/labkit_framework/" + area, true, ...
                "Reason", "LabKit framework GUI test changed");
        end
    elseif numel(parts) >= 5 && parts(4) == "project"
        area = parts(5);
        steps = planStep("gui_project_" + safeRunNamePart(area), ...
            "gui/project/" + area, true, ...
            "Reason", "project GUI test changed");
    else
        steps = planStep("gui", "gui", true, ...
            "Reason", "broad GUI test change needs full GUI coverage");
    end
end

function steps = docPathSteps(parts)
    steps = planStep("project_docs", "project/docs", false, ...
        "Reason", "human documentation changed");
end

function steps = toolPathSteps(parts)
    if numel(parts) >= 2 && parts(2) == "deployment"
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

function tf = isHeadlessRoutingPath(path)
    path = string(path);
    tf = ismember(path, [ ...
        "tests/runLabKitTests.m"]);
end

function tf = isProjectRoutingPath(path)
    path = string(path);
    tf = ismember(path, [ ...
        "AGENTS.md", ...
        "+labkit/AGENTS.md", ...
        "apps/AGENTS.md", ...
        "buildfile.m", ...
        "tests/AGENTS.md"]);
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

function selector = testFileSelector(parts)
    [~, name] = fileparts(char(parts(end)));
    selector = string(name);
end

function slug = appSlug(parts)
    if numel(parts) >= 3
        slug = parts(3);
    else
        slug = "";
    end
end

function target = appGuiSuiteTarget(root, family, slug)
    family = string(family);
    slug = string(slug);

    if strlength(slug) > 0
        appFolder = fullfile(root, "tests", "cases", "gui", "apps", ...
            family, slug);
        if exist(appFolder, "dir") == 7
            target = "gui/apps/" + family + "/" + slug;
            return;
        end
    end

    appFamilyFolder = fullfile(root, "tests", "cases", "gui", "apps", family);
    if exist(appFamilyFolder, "dir") == 7
        target = "gui/apps/" + family;
    else
        target = strings(1, 0);
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
    reason = "";
    if ~isempty(varargin)
        p = inputParser;
        p.FunctionName = "planStep";
        p.addParameter("Tests", tests, @isStringLikeList);
        p.addParameter("Reason", reason, @isTextScalar);
        p.parse(varargin{:});
        tests = normalizeTextList(p.Results.Tests);
        reason = string(p.Results.Reason);
    end
    step = struct( ...
        "RunNameSuffix", string(runNameSuffix), ...
        "Suites", {normalizeTextList(suites)}, ...
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
        "batch_crop_workflow_exports_synthetic_crop"];
end

function tests = fastUiRepresentativeTests()
    tests = [ ...
        "test_gui_layout_ui_declarative_app", ...
        "controlled_interactions_suppress_programmatic_events", ...
        "test_gui_layout_ui_debug_trace"];
end

function tests = fastUiGestureRepresentativeTests()
    tests = "controlled_region_selection_registers_transient_gesture";
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
    steps = struct("RunNameSuffix", {}, "Suites", {}, "Tests", {}, ...
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

    candidateSuites = normalizeTextList(candidate.Suites);
    stepSuites = normalizeTextList(step.Suites);
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
        strjoin(step.Tests, ",") + "|" + string(step.IncludeGui);
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
