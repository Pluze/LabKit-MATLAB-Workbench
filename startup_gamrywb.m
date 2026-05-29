function startup_gamrywb()
%STARTUP_GAMRYWB Configure MATLAB path for GamryElectrochemWorkbench.

    root = fileparts(mfilename('fullpath'));
    legacyDir = fullfile(root, 'legacy');

    addpath(root);
    addpath(fullfile(root, 'apps'), '-end');
    if any(strcmp(strsplit(path, pathsep), legacyDir))
        rmpath(legacyDir);
    end

    fprintf('GamryElectrochemWorkbench loaded from:\n  %s\n', root);
end
