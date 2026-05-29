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
end
