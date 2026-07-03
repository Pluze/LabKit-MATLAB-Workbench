function root = setupLabKitTestPath()
%SETUPLABKITTESTPATH Add repo and shared test paths for official tests.
%
% Expected caller: tests/runLabKitTests.m and official matlab.unittest tests.
% Side effects: adds the repository root, apps, app entry folders, tests,
% tests/runner, and tests/shared to the MATLAB path.

    root = labkitRepoRoot();

    pathEntries = strsplit(path, pathsep);

    pathEntries = addPathIfMissing(root, pathEntries);
    pathEntries = addPathIfMissing(fullfile(root, "apps"), pathEntries, "-end");
    apps = labkit_launcher("list");
    for k = 1:height(apps)
        pathEntries = addPathIfMissing(char(apps.Folder(k)), pathEntries, "-end");
    end
    pathEntries = addPathIfMissing(fullfile(root, "tests"), pathEntries);
    pathEntries = addPathIfMissing(fullfile(root, "tests", "runner"), pathEntries);
    addPathIfMissing(fullfile(root, "tests", "shared"), pathEntries);
end

function pathEntries = addPathIfMissing(folder, pathEntries, varargin)
    if exist(folder, "dir") == 7 && ~any(strcmp(pathEntries, folder))
        addpath(folder, varargin{:});
        pathEntries{end + 1} = folder;
    end
end
