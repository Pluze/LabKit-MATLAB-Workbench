function test_chronoOverlayExport()
%TEST_CHRONOOVERLAYEXPORT Verify chrono overlay alignment and export tables.

    checkGapCenterAlignment();
    checkFallbackAlignment();
    checkMergedExportInterpolation();
end

function checkGapCenterAlignment()
    item = struct();
    item.name = 'synthetic chrono';
    item.t = (0:0.1:0.8).';
    item.Vf = zeros(size(item.t));
    item.Im = zeros(size(item.t));
    item.pulse = struct('ok', true, ...
        'gap_start', 0.3, ...
        'gap_end', 0.5, ...
        'method', 'synthetic');

    [aligned, msg] = labkit_ChronoOverlay_app('__labkit_test__', 'alignByPulseGap', item);

    assertClose(aligned.alignTime, 0.4, 1e-12, ...
        'Chrono overlay gap-center align time');
    assertClose(aligned.tAligned, item.t - 0.4, 1e-12, ...
        'Chrono overlay gap-center aligned vector');
    assertClose(aligned.tAligned_s, aligned.tAligned, ...
        'Chrono overlay aligned-time alias');
    assert(contains(msg, 'blank center'), ...
        'Alignment message should report gap-center alignment.');
end

function checkFallbackAlignment()
    item = struct();
    item.name = 'synthetic fallback chrono';
    item.t = (2:4).';
    item.Vf = zeros(size(item.t));
    item.Im = zeros(size(item.t));
    item.pulse = struct('ok', false, 'message', 'synthetic pulse not found');

    [aligned, msg] = labkit_ChronoOverlay_app('__labkit_test__', 'alignByPulseGap', item);

    assertClose(aligned.alignTime, 2, 1e-12, ...
        'Chrono overlay fallback align time');
    assertClose(aligned.tAligned, [0; 1; 2], 1e-12, ...
        'Chrono overlay fallback aligned vector');
    assert(contains(msg, 'fallback to first sample'), ...
        'Fallback alignment message should explain the first-sample fallback.');
end

function checkMergedExportInterpolation()
    itemA = makeOverlayItem('trace 1.DTA', [-1; 0; 1], ...
        [10; 20; 30], [1; 2; 3]);
    itemB = makeOverlayItem('trace+2.DTA', [-0.5; 0.5], ...
        [100; 200], [10; 20]);
    itemC = makeOverlayItem('single sample.DTA', 0, 42, 5);

    T = labkit_ChronoOverlay_app('__labkit_test__', 'buildOverlayExportTable', ...
        [itemA, itemB, itemC]);

    assertClose(T.TimeGapCenterAligned_s, [-1; -0.5; 0; 0.5; 1], 1e-12, ...
        'Chrono overlay merged aligned-time axis');

    safeA = matlab.lang.makeValidName(itemA.name);
    safeB = matlab.lang.makeValidName(itemB.name);
    safeC = matlab.lang.makeValidName(itemC.name);

    assertHasColumn(T, ['V_' safeA]);
    assertHasColumn(T, ['I_' safeA]);
    assertHasColumn(T, ['V_' safeB]);
    assertHasColumn(T, ['I_' safeB]);
    assertHasColumn(T, ['V_' safeC]);
    assertHasColumn(T, ['I_' safeC]);

    assertClose(T.(['V_' safeA]), [10; 15; 20; 25; 30], 1e-12, ...
        'Chrono overlay voltage interpolation for first item');
    assertClose(T.(['I_' safeA]), [1; 1.5; 2; 2.5; 3], 1e-12, ...
        'Chrono overlay current interpolation for first item');
    assertClose(T.(['V_' safeB]), [NaN; 100; 150; 200; NaN], ...
        'Chrono overlay voltage interpolation for second item');
    assertClose(T.(['I_' safeB]), [NaN; 10; 15; 20; NaN], ...
        'Chrono overlay current interpolation for second item');
    assertClose(T.(['V_' safeC]), NaN(5, 1), ...
        'Chrono overlay single-sample voltage export');
    assertClose(T.(['I_' safeC]), NaN(5, 1), ...
        'Chrono overlay single-sample current export');
end

function item = makeOverlayItem(name, tAligned, Vf, Im)
    item = struct();
    item.name = name;
    item.tAligned = tAligned(:);
    item.tAligned_s = tAligned(:);
    item.Vf = Vf(:);
    item.Im = Im(:);
end

function assertHasColumn(T, name)
    assert(any(strcmp(T.Properties.VariableNames, name)), ...
        'Chrono overlay export table should contain column %s.', name);
end
