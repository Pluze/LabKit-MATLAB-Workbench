function plan = buildfile
%BUILDFILE LabKit build and validation entry points.

    plan = buildplan(localfunctions);
    plan.DefaultTasks = "test";

    catalog = taskCatalog();
    for k = 1:numel(catalog)
        plan(catalog(k).Name).Description = catalog(k).Description;
    end
end

function checkStyleTask(~)
    runCatalogTask("checkStyle");
end

function testTask(~)
    runCatalogTask("test");
end

function testUnitTask(~)
    runCatalogTask("testUnit");
end

function testIntegrationTask(~)
    runCatalogTask("testIntegration");
end

function testProjectTask(~)
    runCatalogTask("testProject");
end

function testLabkitTask(~)
    runCatalogTask("testLabkit");
end

function testLabkitGuiTask(~)
    runCatalogTask("testLabkitGui");
end

function testAppsTask(~)
    runCatalogTask("testApps");
end

function testAppsGuiTask(~)
    runCatalogTask("testAppsGui");
end

function testGuiStructuralTask(~)
    runCatalogTask("testGuiStructural");
end

function testGuiGestureTask(~)
    runCatalogTask("testGuiGesture");
end

function coverageTask(~)
    runCatalogTask("coverage");
end

function listTasksTask(~)
    printTaskCatalog(taskCatalog());
end

function checkProjectTask(~)
    root = fileparts(mfilename("fullpath"));
    checkProjectDefinition(root);
end

function packageDryRunTask(~)
    root = fileparts(mfilename("fullpath"));

    packageCandidates = [ ...
        "+labkit", ...
        "apps", ...
        "docs", ...
        "scripts", ...
        "README.md", ...
        "labkit_launcher.m", ...
        "buildfile.m", ...
        "startup_labkit.m"];
    validationOnly = [ ...
        "tests", ...
        "AGENTS.md"];
    excludedGeneratedOrLocal = [ ...
        "artifacts", ...
        "photos", ...
        "derived", ...
        "project", ...
        "resources/project", ...
        "LabKit.prj", ...
        ".git", ...
        "LABKIT_REFACTOR_ROADMAP.md"];

    assertRelativePathsExist(root, packageCandidates);
    assertRelativePathsExist(root, validationOnly);

    report = struct( ...
        "schemaVersion", 1, ...
        "packageCandidates", {cellstr(packageCandidates)}, ...
        "validationOnly", {cellstr(validationOnly)}, ...
        "excludedGeneratedOrLocal", {cellstr(excludedGeneratedOrLocal)}, ...
        "createsToolbox", false);
    reportFile = writePackageDryRunReport(root, report);

    fprintf("LabKit package dry run wrote:\n  %s\n", reportFile);
    fprintf("Package candidates: %d, validation-only roots/files: %d\n", ...
        numel(packageCandidates), numel(validationOnly));
end

function catalog = taskCatalog()
    catalog = [ ...
        taskSpec("checkStyle", "Run project/style guardrails.", "Suites", "project", "Tags", "Style"), ...
        taskSpec("test", "Run the full non-GUI test entry point.", "IncludeGui", false), ...
        taskSpec("testUnit", "Run official unit tests.", "Tags", "Unit"), ...
        taskSpec("testIntegration", "Run official integration tests.", "Tags", "Integration"), ...
        taskSpec("testProject", "Run project guardrails.", "Suites", "project"), ...
        taskSpec("testLabkit", "Run all reusable labkit non-GUI tests.", "Suites", "labkit", "IncludeGui", false), ...
        taskSpec("testLabkitGui", "Run all reusable labkit GUI tests.", "Suites", "labkit", "IncludeGui", true), ...
        taskSpec("testApps", "Run all app-owned non-GUI tests.", "Suites", "apps", "IncludeGui", false), ...
        taskSpec("testAppsGui", "Run all app-owned GUI tests.", "Suites", "apps", "IncludeGui", true), ...
        taskSpec("testGuiStructural", "Run noninteractive GUI structural tests.", "Suites", "gui", "Tags", "Structural", "IncludeGui", true), ...
        taskSpec("testGuiGesture", "Run noninteractive GUI gesture tests.", "Tags", "Gesture", "IncludeGui", true), ...
        taskSpec("coverage", "Run official tests with coverage artifacts.", "Tags", ["Unit", "Integration"], "IncludeCoverage", true), ...
        taskSpec("listTasks", "List official LabKit build tasks.", "RunTests", false), ...
        taskSpec("checkProject", "Verify optional local MATLAB Project metadata when present.", "RunTests", false), ...
        taskSpec("packageDryRun", "Verify package boundary inventory without exporting.", "RunTests", false)];
end

function spec = taskSpec(name, description, varargin)
    p = inputParser;
    p.FunctionName = "taskSpec";
    p.addParameter("RunTests", true, @isLogicalScalar);
    p.addParameter("Suites", strings(1, 0), @isStringLikeList);
    p.addParameter("Tags", strings(1, 0), @isStringLikeList);
    p.addParameter("IncludeGui", [], @isEmptyOrLogicalScalar);
    p.addParameter("IncludeCoverage", [], @isEmptyOrLogicalScalar);
    p.addParameter("Required", true, @isLogicalScalar);
    p.parse(varargin{:});

    runTests = logical(p.Results.RunTests);
    spec = struct( ...
        "Name", string(name), ...
        "Description", string(description), ...
        "RunTests", runTests, ...
        "Suites", normalizeTextList(p.Results.Suites), ...
        "Tags", normalizeTextList(p.Results.Tags), ...
        "IncludeGui", normalizeOptionalLogical(p.Results.IncludeGui), ...
        "IncludeCoverage", normalizeOptionalLogical(p.Results.IncludeCoverage), ...
        "Required", runTests && logical(p.Results.Required));
end

function runCatalogTask(runName)
    spec = findTaskSpec(runName);
    if ~spec.RunTests
        error("LabKit:Build:CatalogTaskNotRunnable", ...
            "Build task %s is not a test-runner task.", runName);
    end

    args = taskRunArguments(spec);
    runBuildTests(spec.Name, args{:});
end

function spec = findTaskSpec(runName)
    catalog = taskCatalog();
    matches = [catalog.Name] == string(runName);
    if ~any(matches)
        error("LabKit:Build:UnknownCatalogTask", ...
            "Unknown build task catalog entry: %s.", runName);
    end
    spec = catalog(matches);
end

function args = taskRunArguments(spec)
    args = {};
    if ~isempty(spec.Suites)
        args = [args, {"Suites", spec.Suites}];
    end
    if ~isempty(spec.Tags)
        args = [args, {"Tags", spec.Tags}];
    end
    if ~isempty(spec.IncludeGui)
        args = [args, {"IncludeGui", spec.IncludeGui}];
    end
    if ~isempty(spec.IncludeCoverage)
        args = [args, {"IncludeCoverage", spec.IncludeCoverage}];
    end
end

function runBuildTests(runName, varargin)
    root = fileparts(mfilename("fullpath"));
    addpath(fullfile(root, "tests"));
    runLabKitTests(varargin{:}, ...
        "RunName", runName, ...
        "ArtifactsRoot", fullfile(root, "artifacts"));
end

function printTaskCatalog(catalog)
    fprintf("LabKit build tasks:\n");
    for k = 1:numel(catalog)
        fprintf("  %-30s %s\n", catalog(k).Name, catalog(k).Description);
    end
end

function checkProjectDefinition(root)
    projectFile = fullfile(root, "LabKit.prj");
    if exist(projectFile, "file") ~= 2
        fprintf("No local MATLAB Project file found at:\n  %s\n", projectFile);
        fprintf("Run scripts/create_local_matlab_project.m to create one for local IDE use.\n");
        return;
    end

    [proj, shouldCloseProject] = openLabKitProject(projectFile, root);
    cleanup = onCleanup(@() closeProjectIfLoaded(proj, shouldCloseProject));

    if string(proj.Name) ~= "LabKit"
        error("LabKit:Build:ProjectName", ...
            "Expected project name LabKit, found %s.", string(proj.Name));
    end
    if normalizePath(proj.RootFolder) ~= normalizePath(root)
        error("LabKit:Build:ProjectRoot", ...
            "Project root does not match repository root.");
    end

    expectedPaths = expectedProjectPaths(root);
    actualPaths = normalizePaths(projectEntryPaths(proj.ProjectPath));
    for k = 1:numel(expectedPaths)
        if ~any(actualPaths == normalizePath(expectedPaths(k)))
            error("LabKit:Build:ProjectPath", ...
                "Project path is missing required folder: %s", expectedPaths(k));
        end
    end

    assertNoHiddenProjectPath(root, actualPaths);

    startupFiles = normalizePaths(projectEntryPaths(proj.StartupFiles));
    if ~any(startupFiles == normalizePath(fullfile(root, "startup_labkit.m")))
        error("LabKit:Build:ProjectStartup", ...
            "Project startup files must include startup_labkit.m.");
    end

    fprintf("LabKit MATLAB Project metadata verified.\n");
    clear cleanup
end

function [proj, shouldCloseProject] = openLabKitProject(projectFile, root)
    shouldCloseProject = true;
    try
        proj = currentProject;
        if normalizePath(proj.RootFolder) == normalizePath(root)
            shouldCloseProject = false;
            return;
        end
    catch
    end
    proj = openProject(projectFile);
end

function paths = expectedProjectPaths(root)
    paths = string(root);
    appsRoot = fullfile(root, "apps");
    if exist(appsRoot, "dir") == 7
        paths = [paths, string(appsRoot), appPathDirs(appsRoot)];
    end
    paths = unique(paths, "stable");
end

function dirs = appPathDirs(appRoot)
    entries = dir(fullfile(appRoot, "**"));
    entries = entries([entries.isdir]);
    [~, order] = sort(string(fullfile({entries.folder}, {entries.name})));
    entries = entries(order);
    dirs = strings(1, numel(entries));
    dirCount = 0;
    for k = 1:numel(entries)
        entry = entries(k);
        if strcmp(entry.name, ".") || strcmp(entry.name, "..")
            continue;
        end
        child = string(fullfile(entry.folder, entry.name));
        if normalizePath(child) == normalizePath(appRoot) || ...
                ~isProjectPathCandidate(appRoot, child)
            continue;
        end

        dirCount = dirCount + 1;
        dirs(dirCount) = child;
    end
    dirs = dirs(1:dirCount);
end

function tf = isProjectPathCandidate(appRoot, folder)
    rel = extractAfter(normalizePath(folder), strlength(normalizePath(appRoot)) + 1);
    parts = split(rel, "/");
    tf = ~any(startsWith(parts, ".") | startsWith(parts, "+") | ...
        startsWith(parts, "@") | parts == "private");
end

function paths = projectEntryPaths(entries)
    if isempty(entries)
        paths = strings(1, 0);
    elseif isstring(entries) || ischar(entries) || iscellstr(entries)
        paths = string(entries);
    else
        paths = strings(1, numel(entries));
        for k = 1:numel(entries)
            if isprop(entries(k), "File")
                paths(k) = string(entries(k).File);
            else
                paths(k) = string(entries(k));
            end
        end
    end
end

function assertNoHiddenProjectPath(root, actualPaths)
    rootPath = normalizePath(root);
    for k = 1:numel(actualPaths)
        path = actualPaths(k);
        if path == rootPath
            continue;
        end
        if startsWith(path, rootPath + "/")
            relativePath = extractAfter(path, strlength(rootPath) + 1);
        else
            relativePath = path;
        end
        parts = split(relativePath, "/");
        if any(parts == "private" | startsWith(parts, "+") | ...
                startsWith(parts, "@") | startsWith(parts, "."))
            error("LabKit:Build:ProjectHiddenPath", ...
                "Project path includes private/package/hidden folder: %s", path);
        end
    end
end

function assertRelativePathsExist(root, relativePaths)
    for k = 1:numel(relativePaths)
        path = fullfile(root, relativePaths(k));
        if exist(path, "file") ~= 2 && exist(path, "dir") ~= 7
            error("LabKit:Build:PackageDryRunMissingPath", ...
                "Package dry run expected path is missing: %s", relativePaths(k));
        end
    end
end

function reportFile = writePackageDryRunReport(root, report)
    reportDir = fullfile(root, "artifacts", "package");
    if exist(reportDir, "dir") ~= 7
        mkdir(reportDir);
    end
    reportFile = fullfile(reportDir, "package-dry-run.json");
    fid = fopen(reportFile, "w");
    if fid < 0
        error("LabKit:Build:PackageDryRunReport", ...
            "Could not write package dry-run report: %s", reportFile);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, jsonencode(report), "char");
    clear cleanup
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

function value = normalizeOptionalLogical(value)
    if isempty(value)
        return;
    end
    value = logical(value);
end

function tf = isStringLikeList(value)
    tf = ischar(value) || isstring(value) || iscellstr(value);
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end

function tf = isEmptyOrLogicalScalar(value)
    tf = isempty(value) || isLogicalScalar(value);
end

function normalized = normalizePaths(paths)
    normalized = strings(size(paths));
    for k = 1:numel(paths)
        normalized(k) = normalizePath(paths(k));
    end
end

function normalized = normalizePath(path)
    normalized = replace(string(path), "\", "/");
    normalized = regexprep(normalized, "/+$", "");
    normalized = lower(normalized);
end

function closeProjectIfLoaded(proj, shouldCloseProject)
    if ~shouldCloseProject || isempty(proj) || ~isvalid(proj)
        return;
    end
    try
        if proj.isLoaded
            proj.close;
        end
    catch
    end
end
