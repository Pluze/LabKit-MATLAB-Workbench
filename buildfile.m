function plan = buildfile
%BUILDFILE LabKit build and validation entry points.

    plan = buildplan(localfunctions);
    plan.DefaultTasks = "test";

    plan("checkStyle").Description = "Run project/style guardrails.";
    plan("test").Description = "Run the full non-GUI test entry point.";
    plan("testUnit").Description = "Run official unit tests.";
    plan("testIntegration").Description = "Run official integration tests.";
    plan("testGuiStructural").Description = "Run noninteractive GUI structural tests.";
    plan("testGuiGesture").Description = "Run noninteractive/manual GUI gesture tests.";
    plan("coverage").Description = "Run official tests with coverage artifacts.";
    plan("checkProject").Description = "Verify MATLAB Project metadata and path setup.";
    plan("packageDryRun").Description = "Verify package boundary inventory without exporting.";
end

function checkStyleTask(~)
    runBuildTests("checkStyle", ...
        "Suites", "project", ...
        "Tags", "Style", ...
        "FailIfNoTests", false);
end

function testTask(~)
    runBuildTests("test", ...
        "IncludeGui", false, ...
        "FailIfNoTests", false);
end

function testUnitTask(~)
    runBuildTests("testUnit", ...
        "Tags", "Unit", ...
        "FailIfNoTests", false);
end

function testIntegrationTask(~)
    runBuildTests("testIntegration", ...
        "Tags", "Integration", ...
        "FailIfNoTests", false);
end

function testGuiStructuralTask(~)
    runBuildTests("testGuiStructural", ...
        "Suites", "gui", ...
        "Tags", "Structural", ...
        "IncludeGui", true, ...
        "FailIfNoTests", false);
end

function testGuiGestureTask(~)
    runBuildTests("testGuiGesture", ...
        "Tags", "Gesture", ...
        "IncludeGui", true, ...
        "FailIfNoTests", false);
end

function coverageTask(~)
    runBuildTests("coverage", ...
        "Tags", ["Unit", "Integration"], ...
        "IncludeCoverage", true, ...
        "FailIfNoTests", false);
end

function checkProjectTask(~)
    root = fileparts(mfilename("fullpath"));
    checkProjectDefinition(root);
end

function packageDryRunTask(~)
    root = fileparts(mfilename("fullpath"));
    checkProjectDefinition(root);

    packageCandidates = [ ...
        "+labkit", ...
        "apps", ...
        "docs", ...
        "scripts", ...
        "resources/project", ...
        "README.md", ...
        "LabKit.prj", ...
        "buildfile.m", ...
        "startup_labkit.m"];
    validationOnly = [ ...
        "tests", ...
        "AGENTS.md"];
    excludedGeneratedOrLocal = [ ...
        "artifacts", ...
        "photos", ...
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

function runBuildTests(runName, varargin)
    root = fileparts(mfilename("fullpath"));
    addpath(fullfile(root, "tests"));
    runLabKitTests(varargin{:}, ...
        "RunName", runName, ...
        "ArtifactsRoot", fullfile(root, "artifacts"));
end

function checkProjectDefinition(root)
    projectFile = fullfile(root, "LabKit.prj");
    if exist(projectFile, "file") ~= 2
        error("LabKit:Build:MissingProject", ...
            "Expected MATLAB Project file is missing: %s", projectFile);
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
        paths = [paths, string(appsRoot), appPathDirs(appsRoot)]; %#ok<AGROW>
    end
    paths = unique(paths, "stable");
end

function dirs = appPathDirs(appRoot)
    dirs = strings(1, 0);
    entries = dir(appRoot);
    [~, order] = sort({entries.name});
    entries = entries(order);
    for k = 1:numel(entries)
        entry = entries(k);
        if ~entry.isdir || strcmp(entry.name, ".") || strcmp(entry.name, "..")
            continue;
        end
        if startsWith(entry.name, ".") || startsWith(entry.name, "+") || ...
                startsWith(entry.name, "@") || strcmp(entry.name, "private")
            continue;
        end

        child = string(fullfile(entry.folder, entry.name));
        dirs = [dirs, child, appPathDirs(child)]; %#ok<AGROW>
    end
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
