function test_detectPulses()
%TEST_DETECTPULSES Verify extracted pulse detection behavior.

    currentFixture = demoFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
    voltageFixture = demoFixturePath('chrono_chronoamp_voltage_pulse_0p2ms.DTA');

    [currentItem, currentStatus] = gamrywb.dta.loadFile(currentFixture, "chrono");
    assert(currentStatus.ok, currentStatus.message);
    currentMeta = currentItem.meta;
    currentTables = currentItem.tables;
    [currentCurve, currentOk, currentMsg] = gamrywb.dta.getMainCurve(currentTables);
    assert(currentOk, currentMsg);
    currentT = gamrywb.dta.getColumn(currentCurve, 'T');
    currentIm = gamrywb.dta.getColumn(currentCurve, 'Im');

    [currentPulse, currentPulseMsg] = gamrywb.dta.detectPulses(currentT, currentIm, currentMeta);
    assert(currentPulse.ok, currentPulseMsg);
    assert(strcmp(currentPulse.method, 'metadata-current'), 'Current-controlled fixture should use metadata-current detection.');
    assert(abs(currentPulse.cath_start - 1e-3) < 1e-12, 'Current fixture cathodic start should match TSTEP accumulation.');
    assert(abs(currentPulse.cath_end - 1.2e-3) < 1e-12, 'Current fixture cathodic end should match TSTEP accumulation.');
    assert(abs(currentPulse.gap_start - 1.2e-3) < 1e-12 && abs(currentPulse.gap_end - 1.24e-3) < 1e-12, ...
        'Current fixture blank gap should include both 20 us zero-current steps.');
    assert(abs(currentPulse.gap.center_s - 1.22e-3) < 1e-12, 'Current fixture normalized gap center should be populated.');

    [voltageItem, voltageStatus] = gamrywb.dta.loadFile(voltageFixture, "chrono");
    assert(voltageStatus.ok, voltageStatus.message);
    voltageMeta = voltageItem.meta;
    voltageTables = voltageItem.tables;
    [voltageCurve, voltageOk, voltageMsg] = gamrywb.dta.getMainCurve(voltageTables);
    assert(voltageOk, voltageMsg);
    voltageT = gamrywb.dta.getColumn(voltageCurve, 'T');
    voltageIm = gamrywb.dta.getColumn(voltageCurve, 'Im');
    [voltagePulse, voltagePulseMsg] = gamrywb.dta.detectPulses(voltageT, voltageIm, voltageMeta);
    assert(voltagePulse.ok, voltagePulseMsg);
    assert(strcmp(voltagePulse.method, 'metadata-voltage'), 'Voltage-controlled fixture should use metadata-voltage detection.');
    assert(abs(voltagePulse.anod_start - 1.24e-3) < 1e-12, 'Voltage fixture anodic start should match VSTEP timing.');

    t = (0:0.01:0.25).';
    Im = zeros(size(t));
    Im(t >= 0.03 & t <= 0.10) = -1e-3;
    Im(t >= 0.14 & t <= 0.20) = 1e-3;

    meta = struct();
    meta.steps = struct( ...
        'idx', {1, 2, 3}, ...
        'I', {-1e-3, 0, 1e-3}, ...
        'V', {NaN, NaN, NaN}, ...
        'T', {0.10, 0.04, 0.06});

    [pulse, msg] = gamrywb.dta.detectPulses(t, Im, meta);
    assert(pulse.ok, msg);
    assert(strcmp(pulse.method, 'metadata-current'), 'Default mode should prefer metadata.');
    assert(strcmp(msg, 'Metadata pulse detection OK (current-controlled): cath step 1, anod step 3.'), ...
        'Metadata detection message should match legacy wording.');
    assert(abs(pulse.cath_start - 0) < 1e-12 && abs(pulse.cath_end - 0.10) < 1e-12, ...
        'Metadata cathodic timing should match TSTEP accumulation.');
    assert(abs(pulse.gap_start - 0.10) < 1e-12 && abs(pulse.gap_end - 0.14) < 1e-12, ...
        'Metadata gap timing should match legacy fields.');
    assert(abs(pulse.gap.center_s - 0.12) < 1e-12, 'Normalized gap center should be populated.');
    assert(abs(pulse.cath.current_A + 1e-3) < 1e-15, 'Normalized cathodic current should be populated.');

    [uiDefaultPulse, uiDefaultMsg] = gamrywb.dta.detectPulses(t, Im, meta, "Metadata first, then auto");
    assert(uiDefaultPulse.ok, uiDefaultMsg);
    assert(strcmp(uiDefaultPulse.method, 'metadata-current'), ...
        'Legacy GUI default pulse mode text should map to metadata-first detection.');

    opts = struct('mode', "current_only");
    [autoPulse, autoMsg] = gamrywb.dta.detectPulses(t, Im, meta, opts);
    assert(autoPulse.ok, autoMsg);
    assert(strcmp(autoPulse.method, 'auto-from-Im'), 'current_only mode should use current detection.');
    assert(abs(autoPulse.cath_start - 0.03) < 1e-12, 'Auto cathodic start should use first threshold sample.');
    assert(abs(autoPulse.anod_start - 0.14) < 1e-12, 'Auto anodic start should use first later positive segment.');

    [uiAutoPulse, uiAutoMsg] = gamrywb.dta.detectPulses(t, Im, meta, "Auto from Im only");
    assert(uiAutoPulse.ok, uiAutoMsg);
    assert(strcmp(uiAutoPulse.method, 'auto-from-Im'), ...
        'Legacy GUI auto pulse mode text should map to current-only detection.');

    badMeta = struct('steps', struct('idx', {}, 'I', {}, 'V', {}, 'T', {}));
    [fallbackPulse, fallbackMsg] = gamrywb.dta.detectPulses(t, Im, badMeta);
    assert(fallbackPulse.ok, fallbackMsg);
    assert(contains(fallbackMsg, 'fallback success'), 'metadata_first should report current fallback success.');

    [metadataOnlyPulse, metadataOnlyMsg] = gamrywb.dta.detectPulses(t, Im, badMeta, "Metadata only");
    assert(~metadataOnlyPulse.ok, 'Metadata-only mode should fail without metadata steps.');
    assert(strcmp(metadataOnlyMsg, 'Metadata pulse detection: no ISTEP/TSTEP or VSTEP/TSTEP steps found.'), ...
        'Metadata-only failure message should match legacy wording.');
end
