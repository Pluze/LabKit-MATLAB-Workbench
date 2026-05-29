function test_chronoOverlayExport()
%TEST_CHRONOOVERLAYEXPORT Verify chrono overlay export naming stays visible.

    root = fileparts(fileparts(mfilename('fullpath')));
    appFile = fullfile(root, 'apps', 'gamrywb_ChronoOverlay_app.m');
    source = fileread(appFile);

    assert(contains(source, 'TimeGapCenterAligned_s'), ...
        'Chrono overlay export column naming should remain visible in the app source.');
end
