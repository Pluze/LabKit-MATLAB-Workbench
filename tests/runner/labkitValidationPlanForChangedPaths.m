function steps = labkitValidationPlanForChangedPaths(root, changedPaths)
%LABKITVALIDATIONPLANFORCHANGEDPATHS Map changed files to runner selections.
% Expected caller: tests/runLabKitTests.m and runner guardrail tests.
% Inputs:
%   root         repository root used to check app GUI test folders
%   changedPaths relative repository paths from git diff or ls-files
% Output:
%   steps        struct array with RunNameSuffix, Suites, and IncludeGui
% Side effects: none. Unknown paths intentionally fall back to the full
%   non-GUI runner selection rather than returning a narrow false signal.

    changedPaths = normalizeChangedPaths(changedPaths);
    steps = emptyPlanSteps();
    for k = 1:numel(changedPaths)
        steps = [steps, stepsForChangedPath(root, changedPaths(k))];
    end
    steps = compressPlanSteps(uniquePlanSteps(steps));
end

function steps = stepsForChangedPath(root, path)
    parts = split(path, "/").';
    steps = emptyPlanSteps();
    if isempty(parts)
        return;
    end

    first = parts(1);
    if first == "+labkit"
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
    elseif startsWith(first, ".github") || first == ".agents"
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
        "README.md", ...
        "buildfile.m", ...
        "startup_labkit.m", ...
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
    if family == "project"
        target = "gui/labkit/project";
        return;
    end

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

function step = planStep(runNameSuffix, suites, includeGui)
    step = struct( ...
        "RunNameSuffix", string(runNameSuffix), ...
        "Suites", {normalizeTextList(suites)}, ...
        "IncludeGui", logical(includeGui));
end

function steps = emptyPlanSteps()
    steps = struct("RunNameSuffix", {}, "Suites", {}, "IncludeGui", {});
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

function tf = suiteCoveredByAny(candidateSuites, target)
    tf = false;
    target = string(target);
    for k = 1:numel(candidateSuites)
        candidate = string(candidateSuites(k));
        tf = tf || target == candidate || startsWith(target, candidate + "/");
    end
end

function signature = stepSignature(step)
    signature = strjoin(step.Suites, ",") + "|" + string(step.IncludeGui);
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
