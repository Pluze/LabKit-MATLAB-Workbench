function steps = labkitValidationPlanForChangedPaths(root, changedPaths, varargin)
%LABKITVALIDATIONPLANFORCHANGEDPATHS Map changed files to runner selections.
% Expected caller: tests/runLabKitTests.m and runner guardrail tests.
% Inputs:
%   root         repository root used to check app GUI test folders
%   changedPaths relative repository paths from git diff or ls-files
%   Mode         conservative (default) or fast
% Output:
%   steps        struct array with RunNameSuffix, Suites, and IncludeGui
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
    if isProjectRoutingPath(path)
        steps = planStep("project", "project", false);
    elseif first == "+labkit"
        steps = labkitPackageSteps(parts);
    elseif first == "apps"
        steps = appSourceSteps(root, parts);
    elseif first == "tests"
        steps = testPathSteps(root, parts);
    elseif first == "docs"
        steps = docPathSteps(parts);
    elseif isHeadlessRoutingPath(path)
        steps = fullNonGuiStep();
    elseif isProjectRoutingPath(path)
        steps = planStep("project", "project", false);
    elseif startsWith(first, ".github") || first == ".agents" || first == "tools"
        steps = planStep("project", "project", false);
    else
        steps = fullNonGuiStep();
    end
end

function steps = labkitPackageSteps(parts)
    if numel(parts) < 2
        steps = [ ...
            planStep("labkit", "labkit", true), ...
            planStep("gui_apps", "gui/apps", true)];
        return;
    end

    packageName = erase(parts(2), "+");
    switch packageName
        case "ui"
            steps = [ ...
                planStep("labkit_ui", "labkit/ui", true), ...
                planStep("gui_apps", "gui/apps", true)];
        case "dta"
            steps = [ ...
                planStep("labkit_dta", "labkit/dta", false), ...
                planStep("apps_electrochem", "apps/electrochem", false), ...
                planStep("gui_apps_electrochem", "gui/apps/electrochem", true)];
        case "rhs"
            steps = [ ...
                planStep("labkit_rhs", "labkit/rhs", false), ...
                planStep("apps_neurophysiology", "apps/neurophysiology", false)];
        case "biosignal"
            steps = [ ...
                planStep("labkit_biosignal", "labkit/biosignal", false), ...
                planStep("apps_wearable", "apps/wearable", false), ...
                planStep("apps_neurophysiology", "apps/neurophysiology", false), ...
                planStep("gui_apps_wearable", "gui/apps/wearable", true)];
        case "image"
            steps = [ ...
                planStep("labkit_image", "labkit/image", false), ...
                planStep("apps_image_measurement", "apps/image_measurement", false), ...
                planStep("gui_apps_image_measurement", "gui/apps/image_measurement", true)];
        case "thermal"
            steps = [ ...
                planStep("labkit_thermal", "labkit/thermal", false), ...
                planStep("apps_image_measurement", "apps/image_measurement", false), ...
                planStep("gui_apps_image_measurement", "gui/apps/image_measurement", true)];
        otherwise
            steps = [ ...
                planStep("labkit", "labkit", true), ...
                planStep("gui_apps", "gui/apps", true)];
    end
end

function steps = appSourceSteps(root, parts)
    if numel(parts) < 2
        steps = [ ...
            planStep("apps", "apps", false), ...
            planStep("gui_apps", "gui/apps", true)];
        return;
    end

    family = parts(2);
    steps = planStep("apps_" + safeRunNamePart(family), ...
        "apps/" + family, false);
    guiTarget = appGuiSuiteTarget(root, family, appSlug(parts));
    if strlength(guiTarget) > 0
        steps = [steps, planStep(suiteRunNameSuffix(guiTarget), guiTarget, true)];
    end
end

function steps = testPathSteps(root, parts)
    if numel(parts) >= 4 && all(parts(1:3) == ["tests", "cases", "unit"])
        steps = unitTestPathSteps(parts);
    elseif numel(parts) >= 4 && all(parts(1:3) == ["tests", "cases", "gui"])
        steps = guiTestPathSteps(root, parts);
    elseif numel(parts) >= 3 && all(parts(1:2) == ["tests", "cases"])
        steps = planStep("project", "project", false);
    elseif numel(parts) >= 2 && parts(2) == "runner"
        steps = fullNonGuiStep();
    elseif numel(parts) >= 2 && parts(2) == "shared"
        steps = sharedTestPathSteps(parts);
    else
        steps = planStep("project", "project", false);
    end
end

function steps = unitTestPathSteps(parts)
    if numel(parts) >= 5 && parts(4) == "labkit"
        area = parts(5);
        steps = planStep("labkit_" + safeRunNamePart(area), ...
            "labkit/" + area, false);
    elseif numel(parts) >= 5 && parts(4) == "apps"
        family = parts(5);
        steps = planStep("apps_" + safeRunNamePart(family), ...
            "apps/" + family, false);
    elseif numel(parts) >= 4 && parts(4) == "project"
        steps = planStep("project", "project", false);
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
        steps = planStep(suiteRunNameSuffix(target), target, true);
    elseif numel(parts) >= 6 && all(parts(4:5) == ["gesture", "labkit"])
        steps = planStep("labkit_" + safeRunNamePart(parts(6)), ...
            "labkit/" + parts(6), true);
    elseif numel(parts) >= 5 && parts(4) == "labkit"
        area = parts(5);
        if area == "ui"
            steps = planStep("labkit_ui", "labkit/ui", true);
        else
            steps = planStep("gui_labkit_" + safeRunNamePart(area), ...
                "gui/labkit/" + area, true);
        end
    else
        steps = planStep("gui", "gui", true);
    end
end

function steps = docPathSteps(parts)
    steps = planStep("project", "project", false);
end

function steps = sharedTestPathSteps(parts)
    filename = "";
    if ~isempty(parts)
        filename = lower(parts(end));
    end
    if contains(filename, "gui") || contains(filename, "uispec") || ...
            contains(filename, "snapshot")
        steps = planStep("gui", "gui", true);
    else
        steps = fullNonGuiStep();
    end
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
        "README.md", ...
        "buildfile.m", ...
        "tests/AGENTS.md"]);
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
    step = planStep("headless", strings(1, 0), false);
end

function step = planStep(runNameSuffix, suites, includeGui, varargin)
    tests = strings(1, 0);
    if ~isempty(varargin)
        p = inputParser;
        p.FunctionName = "planStep";
        p.addParameter("Tests", tests, @isStringLikeList);
        p.parse(varargin{:});
        tests = normalizeTextList(p.Results.Tests);
    end
    step = struct( ...
        "RunNameSuffix", string(runNameSuffix), ...
        "Suites", {normalizeTextList(suites)}, ...
        "Tests", {tests}, ...
        "IncludeGui", logical(includeGui));
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

    if any(suites == "labkit/ui")
        steps = [ ...
            planStep("labkit_ui", "labkit/ui", false), ...
            planStep("gui_labkit_ui_representative", "gui/labkit/ui", true, ...
            "Tests", fastUiRepresentativeTests())];
    elseif any(suites == "gui")
        steps = planStep("gui_representative", ...
            ["gui/labkit/ui", ...
            "gui/apps/image_measurement/image_enhance", ...
            "gui/apps/image_measurement/batch_crop"], true, ...
            "Tests", fastGuiRepresentativeTests());
    elseif any(suites == "gui/apps")
        steps = planStep("gui_apps_representative", ...
            ["gui/apps/image_measurement/image_enhance", ...
            "gui/apps/image_measurement/batch_crop"], true, ...
            "Tests", ["image_enhance_layout", "batch_crop_layout"]);
    else
        steps = step;
    end
end

function tests = fastGuiRepresentativeTests()
    tests = [ ...
        "image_enhance_layout", ...
        "batch_crop_layout", ...
        fastUiRepresentativeTests()];
end

function tests = fastUiRepresentativeTests()
    tests = [ ...
        "test_gui_layout_ui_declarative_app", ...
        "test_gui_layout_ui_debug_trace"];
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
        "IncludeGui", {});
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
