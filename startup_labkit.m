function startup_labkit(printBanner)
%STARTUP_LABKIT Configure MATLAB path for LabKit workbench apps.

    if nargin < 1 || isempty(printBanner)
        printBanner = true;
    end
    printBanner = logical(printBanner);

    persistent hasInitialized;
    if isempty(hasInitialized)
        hasInitialized = false;
    end
    root = fileparts(mfilename('fullpath'));

    if ~hasInitialized
        addpath(root);
        addpath(fullfile(root, 'apps'), '-end');
        appDirs = appPathDirs(fullfile(root, 'apps'));
        for k = 1:numel(appDirs)
            addpath(appDirs{k}, '-end');
        end
        hasInitialized = true;
    end

    if printBanner
        fprintf('LabKit workbench loaded from:\n  %s\n', root);
    end
end

function dirs = appPathDirs(appRoot)
    dirs = {};
    if exist(appRoot, 'dir') ~= 7
        return;
    end

    entries = dir(appRoot);
    for k = 1:numel(entries)
        entry = entries(k);
        if ~entry.isdir || ismember(entry.name, {'.', '..'})
            continue;
        end
        if shouldSkipAppDir(entry.name)
            continue;
        end

        fullpath = fullfile(appRoot, entry.name);
        dirs{end+1} = fullpath;
        childDirs = appPathDirs(fullpath);
        dirs = [dirs childDirs];
    end
end

function tf = shouldSkipAppDir(name)
    tf = startsWith(name, '.') || startsWith(name, '+') ...
        || startsWith(name, '@') || strcmp(name, 'private');
end
