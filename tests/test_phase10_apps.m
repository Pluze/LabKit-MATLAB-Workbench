function test_phase10_apps()
%TEST_PHASE10_APPS Verify Phase 10 app entry points resolve.

    root = fileparts(fileparts(mfilename('fullpath')));
    apps = { ...
        'gamrywb_CIC_app', ...
        'gamrywb_VTResistance_app', ...
        'gamrywb_CSC_app', ...
        'gamrywb_EIS_app'};

    for i = 1:numel(apps)
        appFile = fullfile(root, 'apps', [apps{i} '.m']);
        assert(exist(appFile, 'file') == 2, ['Missing app entry point: ' apps{i}]);
        assert(~isempty(which(apps{i})), ['App entry point does not resolve: ' apps{i}]);
    end

    eisAppFile = fullfile(root, 'apps', 'gamrywb_EIS_app.m');
    eisSource = fileread(eisAppFile);
    assert(~contains(eisSource, '_legacy'), 'gamrywb_EIS_app should not call legacy implementations.');
    assert(~contains(eisSource, 'gamry_EIS_multiDTA_plot_gui('), ...
        'gamrywb_EIS_app should not delegate to the root legacy-compatible EIS wrapper.');

    cscAppFile = fullfile(root, 'apps', 'gamrywb_CSC_app.m');
    cscSource = fileread(cscAppFile);
    assert(~contains(cscSource, '_legacy'), 'gamrywb_CSC_app should not call legacy implementations.');
    assert(~contains(cscSource, 'gamry_CV_CSC_dta_gui('), ...
        'gamrywb_CSC_app should not delegate to the root legacy-compatible CSC wrapper.');

    vtAppFile = fullfile(root, 'apps', 'gamrywb_VTResistance_app.m');
    vtSource = fileread(vtAppFile);
    assert(~contains(vtSource, '_legacy'), 'gamrywb_VTResistance_app should not call legacy implementations.');
    assert(~contains(vtSource, 'gamry_VT_resistance_gui('), ...
        'gamrywb_VTResistance_app should not delegate to a removed root legacy-compatible VT wrapper.');

    cicAppFile = fullfile(root, 'apps', 'gamrywb_CIC_app.m');
    cicSource = fileread(cicAppFile);
    assert(~contains(cicSource, 'gamry_CIC_VT_gui_paperlabels('), ...
        'gamrywb_CIC_app should not delegate to a removed root legacy-compatible CIC wrapper.');
end
