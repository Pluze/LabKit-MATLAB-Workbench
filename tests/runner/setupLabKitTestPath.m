function root = setupLabKitTestPath()
%SETUPLABKITTESTPATH Add repo and shared test paths for official tests.
%
% Expected caller: tests/runLabKitTests.m and official matlab.unittest tests.
% Side effects: adds the repository root, apps, app entry folders, tests,
% tests/runner, and tests/shared to the MATLAB path.

    root = labkitRepoRoot();

    pathEntries = strsplit(path, pathsep);

    pathEntries = addPathsIfMissing(root, pathEntries);
    pathEntries = addPathsIfMissing( ...
        fullfile(root, "apps"), pathEntries, "-end");
    appFolders = publicAppEntryFolders(root);
    pathEntries = addPathsIfMissing(appFolders, pathEntries, "-end");
    pathEntries = addPathsIfMissing( ...
        fullfile(root, "tests"), pathEntries);
    pathEntries = addPathsIfMissing( ...
        fullfile(root, "tests", "runner"), pathEntries);
    addPathsIfMissing(fullfile(root, "tests", "shared"), pathEntries);
end

function folders = publicAppEntryFolders(root)
    entries = dir(fullfile(root, "apps", "**", "labkit_*_app.m"));
    folders = unique(string({entries.folder}), "stable");
    folders = sort(folders);
end

function pathEntries = addPathsIfMissing(folders, pathEntries, varargin)
    folders = string(folders);
    folders = folders(arrayfun(@(folder) ...
        exist(folder, "dir") == 7, folders));
    folders = folders(~ismember(folders, string(pathEntries)));
    if isempty(folders)
        return;
    end
    addpath(char(strjoin(folders, pathsep)), varargin{:});
    pathEntries = [pathEntries, cellstr(folders)];
end
