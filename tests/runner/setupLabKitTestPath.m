function root = setupLabKitTestPath()
%SETUPLABKITTESTPATH Add repo and shared test paths for official tests.
%
% Expected caller: tests/runLabKitTests.m and official matlab.unittest tests.
% Side effects: adds the repository root, apps, app entry folders, tests,
% tests/runner, and tests/shared to the MATLAB path.

    persistent configuredRoot
    root = labkitRepoRoot();
    if isequal(configuredRoot, string(root))
        return;
    end

    addPathIfMissing(root);
    addPathIfMissing(fullfile(root, "apps"), "-end");
    apps = labkit_launcher("list");
    for k = 1:height(apps)
        addPathIfMissing(char(apps.Folder(k)), "-end");
    end
    addPathIfMissing(fullfile(root, "tests"));
    addPathIfMissing(fullfile(root, "tests", "runner"));
    addPathIfMissing(fullfile(root, "tests", "shared"));
    configuredRoot = string(root);
end

function addPathIfMissing(folder, varargin)
    if exist(folder, "dir") == 7 && ~pathContains(folder)
        addpath(folder, varargin{:});
    end
end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end
