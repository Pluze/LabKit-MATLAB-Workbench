function test_phase1_smoke()
%TEST_PHASE1_SMOKE Check startup path and legacy reference boundaries.

    root = fileparts(fileparts(mfilename('fullpath')));
    legacyDir = fullfile(root, 'legacy');

    assert(exist(fullfile(root, 'startup_gamrywb.m'), 'file') == 2, 'startup_gamrywb.m is missing.');
    assert(exist(fullfile(root, '+gamrywb', '+util', 'shortName.m'), 'file') == 2, 'Utility package is missing.');
    assert(~pathContains(legacyDir), 'startup_gamrywb should not add legacy/ to the default path.');

    legacyNames = { ...
        'gamry_CIC_VT_gui_paperlabels', ...
        'gamry_VT_resistance_gui', ...
        'gamry_CV_CSC_dta_gui', ...
        'gamry_EIS_multiDTA_plot_gui', ...
        'gamry_multiDTA_plot_export_gui'};

    for i = 1:numel(legacyNames)
        rootFile = fullfile(root, [legacyNames{i} '.m']);
        legacyImpl = fullfile(root, 'legacy', [legacyNames{i} '_legacy.m']);

        assert(exist(rootFile, 'file') == 0, ['Root legacy wrapper should be removed: ' legacyNames{i}]);
        assert(exist(legacyImpl, 'file') == 2, ['Missing legacy reference implementation: ' legacyNames{i}]);
        assert(isempty(which(legacyNames{i})), ['Original legacy command should not resolve by default: ' legacyNames{i}]);
    end

    assert(exist(fullfile(root, 'demo', 'cv_cyclic_voltammetry_pt_reference.DTA'), 'file') == 2, ...
        'Demo fixture cv_cyclic_voltammetry_pt_reference.DTA is missing.');
end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end
