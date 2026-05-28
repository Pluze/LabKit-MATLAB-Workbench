function test_phase1_smoke()
%TEST_PHASE1_SMOKE Check Phase 1 structure and compatibility entry points.

    root = fileparts(fileparts(mfilename('fullpath')));

    assert(exist(fullfile(root, 'startup_gamrywb.m'), 'file') == 2, 'startup_gamrywb.m is missing.');
    assert(exist(fullfile(root, '+gamrywb', '+util', 'shortName.m'), 'file') == 2, 'Utility package is missing.');

    names = { ...
        'gamry_CIC_VT_gui_paperlabels', ...
        'gamry_VT_resistance_gui', ...
        'gamry_CV_CSC_dta_gui', ...
        'gamry_EIS_multiDTA_plot_gui', ...
        'gamry_multiDTA_plot_export_gui'};

    for i = 1:numel(names)
        rootFile = fullfile(root, [names{i} '.m']);
        legacyShim = fullfile(root, 'legacy', [names{i} '.m']);
        legacyImpl = fullfile(root, 'legacy', [names{i} '_legacy.m']);

        assert(exist(rootFile, 'file') == 2, ['Missing root wrapper: ' names{i}]);
        assert(exist(legacyShim, 'file') == 2, ['Missing legacy shim: ' names{i}]);
        assert(exist(legacyImpl, 'file') == 2, ['Missing legacy implementation: ' names{i}]);
        assert(~isempty(which(names{i})), ['Wrapper does not resolve: ' names{i}]);
    end

    assert(exist(fullfile(root, 'demo', 'Pt.DTA'), 'file') == 2, 'Demo fixture Pt.DTA is missing.');
end
