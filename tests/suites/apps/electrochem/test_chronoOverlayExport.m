function test_chronoOverlayExport()
%TEST_CHRONOOVERLAYEXPORT Verify chrono overlay export naming stays visible.

    root = testRepoRoot();
    appFile = appEntryFile(root, 'labkit_ChronoOverlay_app');
    source = fileread(appFile);

    assert(contains(source, 'TimeGapCenterAligned_s'), ...
        'Chrono overlay export column naming should remain visible in the app source.');
end
