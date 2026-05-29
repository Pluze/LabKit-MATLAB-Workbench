function test_phase1_smoke()
%TEST_PHASE1_SMOKE Check Phase 1 structure and compatibility entry points.

    root = fileparts(fileparts(mfilename('fullpath')));
    legacyDir = fullfile(root, 'legacy');

    assert(exist(fullfile(root, 'startup_gamrywb.m'), 'file') == 2, 'startup_gamrywb.m is missing.');
    assert(exist(fullfile(root, '+gamrywb', '+util', 'shortName.m'), 'file') == 2, 'Utility package is missing.');
    assert(~pathContains(legacyDir), 'startup_gamrywb should not add legacy/ to the default path.');

    names = { ...
        'gamry_CIC_VT_gui_paperlabels', ...
        'gamry_VT_resistance_gui', ...
        'gamry_CV_CSC_dta_gui', ...
        'gamry_EIS_multiDTA_plot_gui', ...
        'gamry_multiDTA_plot_export_gui'};

    for i = 1:numel(names)
        rootFile = fullfile(root, [names{i} '.m']);
        legacyImpl = fullfile(root, 'legacy', [names{i} '_legacy.m']);

        assert(exist(rootFile, 'file') == 2, ['Missing root wrapper: ' names{i}]);
        assert(exist(legacyImpl, 'file') == 2, ['Missing legacy implementation: ' names{i}]);
        assert(strcmp(which(names{i}), rootFile), ['Root wrapper does not resolve first: ' names{i}]);
    end

    assert(exist(fullfile(root, 'demo', 'cv_cyclic_voltammetry_pt_reference.DTA'), 'file') == 2, ...
        'Demo fixture cv_cyclic_voltammetry_pt_reference.DTA is missing.');
end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end
