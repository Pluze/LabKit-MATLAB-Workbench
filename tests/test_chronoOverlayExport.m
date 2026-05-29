function test_chronoOverlayExport()
%TEST_CHRONOOVERLAYEXPORT Verify chrono overlay workflow stays app-local.

    root = fileparts(fileparts(mfilename('fullpath')));
    appFile = fullfile(root, 'apps', 'gamrywb_ChronoOverlay_app.m');
    source = fileread(appFile);

    assert(~contains(source, 'gamrywb_apps.chrono'), ...
        'Chrono overlay app should not depend on the transitional gamrywb_apps.chrono package.');
    assert(contains(source, 'function [item, msg] = alignByPulseGap'), ...
        'Pulse-gap alignment should be local to the Chrono overlay app file.');
    assert(contains(source, 'function T = buildOverlayExportTable'), ...
        'Overlay export table construction should be local to the Chrono overlay app file.');
    assert(contains(source, 'function plotVTIT'), ...
        'Overlay plotting should be local to the Chrono overlay app file.');
    assert(contains(source, 'TimeGapCenterAligned_s'), ...
        'Chrono overlay export column naming should remain visible in the app source.');

    assert(exist(fullfile(root, 'apps', '+gamrywb_apps', '+chrono'), 'dir') ~= 7, ...
        'The transitional gamrywb_apps.chrono package should be removed.');
end
