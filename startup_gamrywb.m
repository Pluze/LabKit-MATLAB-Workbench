function startup_gamrywb()
%STARTUP_GAMRYWB Configure MATLAB path for GamryElectrochemWorkbench.

    root = fileparts(mfilename('fullpath'));

    addpath(root);
    addpath(fullfile(root, 'apps'), '-end');
    appDirs = appPathDirs(fullfile(root, 'apps'));
    for k = 1:numel(appDirs)
        addpath(appDirs{k}, '-end');
    end

    fprintf('GamryElectrochemWorkbench loaded from:\n  %s\n', root);
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
        dirs{end+1} = fullpath; %#ok<AGROW>
        childDirs = appPathDirs(fullpath);
        dirs = [dirs childDirs]; %#ok<AGROW>
    end
end

function tf = shouldSkipAppDir(name)
    tf = startsWith(name, '.') || startsWith(name, '+') ...
        || startsWith(name, '@') || strcmp(name, 'private');
end
