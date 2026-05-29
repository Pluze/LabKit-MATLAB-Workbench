function test_phase1_smoke()
%TEST_PHASE1_SMOKE Check startup path and root entrypoint boundaries.

    root = fileparts(fileparts(mfilename('fullpath')));

    assert(exist(fullfile(root, 'startup_gamrywb.m'), 'file') == 2, 'startup_gamrywb.m is missing.');
    assert(exist(fullfile(root, '+gamrywb', '+util', 'shortName.m'), 'file') == 2, 'Utility package is missing.');
    assert(exist(fullfile(root, 'legacy'), 'dir') == 0, 'legacy/ should be removed after app entry points are package-backed.');

    removedRootNames = { ...
        'gamry_CIC_VT_gui_paperlabels', ...
        'gamry_VT_resistance_gui', ...
        'gamry_CV_CSC_dta_gui', ...
        'gamry_EIS_multiDTA_plot_gui', ...
        'gamry_multiDTA_plot_export_gui'};

    for i = 1:numel(removedRootNames)
        rootFile = fullfile(root, [removedRootNames{i} '.m']);

        assert(exist(rootFile, 'file') == 0, ['Root legacy wrapper should be removed: ' removedRootNames{i}]);
        assert(isempty(which(removedRootNames{i})), ['Original legacy command should not resolve by default: ' removedRootNames{i}]);
    end

    assert(exist(demoFixturePath('cv_cyclic_voltammetry_pt_reference.DTA'), 'file') == 2, ...
        'Demo fixture cv_cyclic_voltammetry_pt_reference.DTA is missing.');
end
