function proj = create_local_matlab_project()
%CREATE_LOCAL_MATLAB_PROJECT Create or refresh the optional local LabKit project.
%
% Usage:
%   proj = create_local_matlab_project
%
% This helper is for MATLAB desktop users who want Project features such as
% dependency analysis, Project Issues, and shortcuts. The generated LabKit.prj
% and resources/project/ metadata are local IDE state and are intentionally
% ignored by git.

    root = fileparts(fileparts(mfilename('fullpath')));
    projectFile = fullfile(root, 'LabKit.prj');

    proj = openOrCreateProject(root, projectFile);
    addProjectFiles(proj, root);
    addProjectPath(proj, root);
    addProjectStartup(proj, root);

    startup_labkit(false);
    fprintf('LabKit local MATLAB Project is ready:\n  %s\n', projectFile);
end

function proj = openOrCreateProject(root, projectFile)
    try
        current = currentProject;
        if samePath(current.RootFolder, root)
            proj = current;
            return;
        end
    catch
    end

    if exist(projectFile, 'file') == 2
        proj = openProject(projectFile);
    else
        proj = matlab.project.createProject('Folder', root, 'Name', 'LabKit');
    end
end

function addProjectFiles(proj, root)
    roots = [ ...
        "+labkit", ...
        "apps", ...
        "tests", ...
        "docs", ...
        "scripts", ...
        ".github"];
    for k = 1:numel(roots)
        pathValue = fullfile(root, roots(k));
        if exist(pathValue, 'dir') == 7
            addProjectItemIfMissing(proj, pathValue, true);
        end
    end

    files = [ ...
        "README.md", ...
        "AGENTS.md", ...
        ".gitignore", ...
        "buildfile.m", ...
        "startup_labkit.m", ...
        "labkit_launcher.m"];
    for k = 1:numel(files)
        pathValue = fullfile(root, files(k));
        if exist(pathValue, 'file') == 2
            addProjectItemIfMissing(proj, pathValue, false);
        end
    end
end

function addProjectPath(proj, root)
    folders = expectedProjectPaths(root);
    existing = normalizePaths(projectEntryPaths(proj.ProjectPath));
    toAdd = strings(1, numel(folders));
    addCount = 0;
    for k = 1:numel(folders)
        if ~any(existing == normalizePath(folders(k)))
            addCount = addCount + 1;
            toAdd(addCount) = folders(k);
        end
    end
    toAdd = toAdd(1:addCount);
    if ~isempty(toAdd)
        addPath(proj, toAdd);
    end
end

function addProjectStartup(proj, root)
    startupFile = string(fullfile(root, 'startup_labkit.m'));
    existing = normalizePaths(projectEntryPaths(proj.StartupFiles));
    if exist(startupFile, 'file') == 2 && ~any(existing == normalizePath(startupFile))
        addStartupFile(proj, startupFile);
    end
end

function addProjectItemIfMissing(proj, pathValue, recursive)
    pathValue = string(pathValue);
    if projectContainsFile(proj, pathValue)
        return;
    end

    try
        if recursive
            addFolderIncludingChildFiles(proj, pathValue);
        else
            addFile(proj, pathValue);
        end
    catch ME
        if ~contains(ME.identifier, 'Already') && ~contains(ME.message, 'already')
            rethrow(ME);
        end
    end
end

function tf = projectContainsFile(proj, pathValue)
    tf = false;
    files = proj.Files;
    wanted = normalizePath(pathValue);
    for k = 1:numel(files)
        if normalizePath(projectFilePath(files(k))) == wanted
            tf = true;
            return;
        end
    end
end

function pathValue = projectFilePath(fileEntry)
    if isprop(fileEntry, 'Path')
        pathValue = string(fileEntry.Path);
    elseif isprop(fileEntry, 'File')
        pathValue = string(fileEntry.File);
    else
        pathValue = string(fileEntry);
    end
end

function paths = expectedProjectPaths(root)
    paths = string(root);
    appsRoot = fullfile(root, 'apps');
    if exist(appsRoot, 'dir') == 7
        paths = [paths, string(appsRoot), appPathDirs(appsRoot)];
    end
    paths = unique(paths, 'stable');
end

function dirs = appPathDirs(appRoot)
    entries = dir(fullfile(appRoot, '**'));
    entries = entries([entries.isdir]);
    [~, order] = sort(string(fullfile({entries.folder}, {entries.name})));
    entries = entries(order);
    dirs = strings(1, numel(entries));
    dirCount = 0;
    for k = 1:numel(entries)
        entry = entries(k);
        if any(strcmp(entry.name, {'.', '..'}))
            continue;
        end
        child = string(fullfile(entry.folder, entry.name));
        if samePath(child, appRoot) || ~isProjectPathCandidate(appRoot, child)
            continue;
        end
        dirCount = dirCount + 1;
        dirs(dirCount) = child;
    end
    dirs = dirs(1:dirCount);
end

function tf = isProjectPathCandidate(appRoot, folder)
    rel = extractAfter(normalizePath(folder), strlength(normalizePath(appRoot)) + 1);
    parts = split(rel, '/');
    tf = ~any(startsWith(parts, '.') | startsWith(parts, '+') | ...
        startsWith(parts, '@') | parts == 'private');
end

function paths = projectEntryPaths(entries)
    if isempty(entries)
        paths = strings(1, 0);
    elseif isstring(entries) || ischar(entries) || iscellstr(entries)
        paths = string(entries);
    else
        paths = strings(1, numel(entries));
        for k = 1:numel(entries)
            if isprop(entries(k), 'File')
                paths(k) = string(entries(k).File);
            else
                paths(k) = string(entries(k));
            end
        end
    end
end

function paths = normalizePaths(paths)
    paths = arrayfun(@normalizePath, string(paths));
end

function pathValue = normalizePath(pathValue)
    pathValue = replace(string(pathValue), '\', '/');
    pathValue = erase(pathValue, '/.');
end

function tf = samePath(left, right)
    tf = normalizePath(left) == normalizePath(right);
end
