function startup_gamrywb()
%STARTUP_GAMRYWB Configure MATLAB path for GamryElectrochemWorkbench.

    root = fileparts(mfilename('fullpath'));

    addpath(root);
    addpath(fullfile(root, 'apps'), '-end');

    fprintf('GamryElectrochemWorkbench loaded from:\n  %s\n', root);
end
