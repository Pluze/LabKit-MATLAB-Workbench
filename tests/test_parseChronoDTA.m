function test_parseChronoDTA()
%TEST_PARSECHRONODTA Verify extracted chrono DTA parser and accessors.

    filepaths = gamrywb.dta.findFiles(demoFixtureDir());
    assert(numel(filepaths) >= 8, 'findFiles should find the demo DTA fixtures.');
    assert(all(endsWith(lower(string(filepaths)), '.dta')), 'findFiles should return only DTA files.');
    assert(any(endsWith(string(filepaths), fullfile('demo', 'chrono_chronopot_current_pulse_0p2ms.DTA'))), ...
        'findDTAFilesRecursive should include the current-controlled chrono fixture.');
    assert(any(endsWith(string(filepaths), fullfile('demo', 'chrono_chronoamp_voltage_pulse_0p2ms.DTA'))), ...
        'findDTAFilesRecursive should include the voltage-controlled chrono fixture.');

    currentFile = demoFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
    voltageFile = demoFixturePath('chrono_chronoamp_voltage_pulse_0p2ms.DTA');

    [currentItem, currentStatus] = gamrywb.dta.loadFile(currentFile, "chrono");
    assert(currentStatus.ok, currentStatus.message);
    meta = currentItem.meta;
    tables = currentItem.tables;
    logmsg = currentItem.logmsg;

    assert(abs(meta.area_cm2 - 1) < 1e-12, 'AREA metadata should be parsed from current chrono fixture.');
    assert(abs(meta.sampleTime_s - 1.00002e-5) < 1e-12, 'SAMPLETIME metadata should be parsed from current chrono fixture.');
    assert(meta.controlMode == "current", 'Current chrono fixture should expose current control mode.');
    assert(currentItem.controlMode == "current", 'Current chrono item should expose current control mode.');
    assert(numel(meta.steps) == 6, 'Current-controlled fixture should produce six ISTEP/TSTEP steps.');
    assert(abs(meta.steps(2).I + 1.22e-2) < 1e-15 && abs(meta.steps(5).I - 1.22e-2) < 1e-15, ...
        'Current-controlled step values should be preserved.');
    assert(any(strcmp({tables.name}, 'Curve')), 'Curve table should be parsed from current chrono fixture.');
    assert(any(contains(string(logmsg), 'Table Curve parsed: 244 rows x 10 cols.')), ...
        'Parser log should include current chrono table dimensions.');

    [curve, ok, msg] = gamrywb.dta.getMainCurve(tables);
    assert(ok, msg);
    assert(strcmp(msg, 'Using table: Curve'), 'Main curve message should match legacy wording.');

    t = gamrywb.dta.getColumn(curve, 'T');
    vf = gamrywb.dta.getColumn(curve, 'Vf');
    im = gamrywb.dta.getColumn(curve, 'im');
    missing = gamrywb.dta.getColumn(curve, 'MissingColumn');

    assert(numel(t) == 244 && numel(vf) == 244 && numel(im) == 244, 'Main chrono columns should use the Curve table.');
    assert(t(1) > 0 && t(1) < 2e-5 && t(end) > 0.0024 && t(end) < 0.0025, ...
        'T column should match current chrono fixture bounds.');
    assert(any(im < 0) && any(im > 0), 'Current-controlled chrono fixture should contain cathodic and anodic current.');
    assert(isempty(missing), 'Missing columns should return empty.');

    [voltageItem, voltageStatus] = gamrywb.dta.loadFile(voltageFile, "chrono");
    assert(voltageStatus.ok, voltageStatus.message);
    vMeta = voltageItem.meta;
    vTables = voltageItem.tables;
    assert(vMeta.controlMode == "voltage", 'Voltage chrono fixture should expose voltage control mode.');
    assert(voltageItem.controlMode == "voltage", 'Voltage chrono item should expose voltage control mode.');
    assert(numel(vMeta.steps) == 6, 'Voltage-controlled fixture should produce six VSTEP/TSTEP steps.');
    assert(abs(vMeta.steps(2).V + 1.5) < 1e-15 && abs(vMeta.steps(5).V - 1.5) < 1e-15, ...
        'Voltage-controlled step values should be preserved.');
    [vCurve, vOk, vMsg] = gamrywb.dta.getMainCurve(vTables);
    assert(vOk, vMsg);
    assert(numel(gamrywb.dta.getColumn(vCurve, 'Im')) == 244, 'Voltage-controlled fixture should expose the Im column.');
end
