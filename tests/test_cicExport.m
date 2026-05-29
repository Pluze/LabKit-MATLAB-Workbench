function test_cicExport()
%TEST_CICEXPORT Verify app-side CIC result/export table helpers.

    item = makeChronoFixtureItem('', 'chrono "cic".DTA');

    opts = struct();
    opts.delay_s = 10e-6;
    opts.cathLimit = -0.6;
    opts.anodLimit = 0.8;
    opts.areaOverride = '';
    opts.pulseMode = 'Metadata first, then auto';
    opts.usedMeasuredCurrent = true;
    item.analysis = computeCIC(item, opts);
    assert(item.analysis.ok, item.analysis.message);

    failed = struct();
    failed.filepath = 'failed.DTA';
    failed.name = 'failed "file".DTA';
    failed.meta = [];
    failed.tables = [];
    failed.analysis = struct('ok', false, 'message', 'bad "msg"');

    items = [item failed];

    T = buildCICResultsTable(items, 'mC/cm^2');
    expectedNames = {'File', 'Amp_A', 'Emc_V', 'Ema_V', 'Qc_C', 'Qa_C', 'Qt_C', ...
        'CICc_mCcm2', 'CICa_mCcm2', 'CICt_mCcm2', 'Safe', 'Detection'};
    assert(isequal(T.Properties.VariableNames, expectedNames), ...
        'CIC export table headers should preserve legacy mC CSV names.');
    assertClose(T.Amp_A(1), item.analysis.ampEstimate_A, 1e-15, 'CIC amp export value');
    assertClose(T.CICc_mCcm2(1), item.analysis.CICc_mCcm2, 1e-15, 'CIC mC cathodic value');
    assert(T.Safe(1) == item.analysis.safe, 'CIC safe flag should be preserved.');
    assert(strcmp(T.Detection{1}, item.analysis.detectMode), 'CIC detection mode should be preserved.');
    assert(isnan(T.Amp_A(2)) && isnan(T.CICt_mCcm2(2)), 'Failed CIC rows should use NaN numeric values.');
    assert(T.Safe(2) == 0, 'Failed CIC rows should preserve legacy Safe=0.');
    assert(strcmp(T.Detection{2}, 'failed'), 'Failed CIC rows should preserve legacy failed detection label.');

    Tu = buildCICResultsTable(item, 'uC/cm^2');
    assert(isequal(Tu.Properties.VariableNames(8:10), {'CICc_uCcm2', 'CICa_uCcm2', 'CICt_uCcm2'}), ...
        'CIC export table headers should preserve legacy uC CSV names.');
    assertClose(Tu.CICc_uCcm2(1), 1e3 * item.analysis.CICc_mCcm2, 1e-12, 'CIC uC cathodic value');

    [C, cols] = buildCICBatchTableData(items, 'uC/cm^2');
    assert(isequal(cols, {'File','Amp(A)','Emc(V)','Ema(V)','Qc(uC/cm^2)','Qa(uC/cm^2)','Qtot(uC/cm^2)','Safe'}), ...
        'CIC batch UI table headers should preserve legacy unit labels.');
    assert(isequal(size(C), [2 8]), 'CIC batch UI table should preserve legacy 8-column shape.');
    assertClose(C{1, 5}, 1e3 * item.analysis.CICc_mCcm2, 1e-12, 'CIC batch UI scaled Qc value');
    assert(strcmp(C{1, 8}, item.analysis.limitSide), 'CIC batch UI unsafe label should preserve limit side.');
    assert(strcmp(C{2, 8}, 'parse/analyze failed'), 'CIC batch UI failed rows should preserve failure label.');

    tmp = [tempname '.csv'];
    cleaner = onCleanup(@() deleteIfExists(tmp));
    writeCICResultsCSV(items, tmp, 'mC/cm^2');
    txt = fileread(tmp);
    header = 'File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,CICc_mCcm2,CICa_mCcm2,CICt_mCcm2,Safe,Detection';
    assert(startsWith(string(txt), header), 'CIC CSV header should preserve legacy spelling and order.');
    assert(contains(string(txt), '"chrono "cic".DTA"'), 'CIC CSV should preserve legacy unescaped quoted file text.');
    assert(contains(string(txt), '"metadata-current"'), 'CIC CSV should preserve detection field.');
    assert(contains(string(txt), '"failed "file".DTA",,,,,,,,,,0,"failed"'), ...
        'CIC CSV failed rows should preserve legacy empty fields and failed marker.');
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end

function A = computeCIC(item, opts)
    A = gamrywb_CIC_app('__test_computeCIC__', item, opts);
end

function T = buildCICResultsTable(items, unitLabel)
    T = gamrywb_CIC_app('__test_buildResultsTable__', items, unitLabel);
end

function [C, cols] = buildCICBatchTableData(items, unitLabel)
    [C, cols] = gamrywb_CIC_app('__test_buildBatchTableData__', items, unitLabel);
end

function writeCICResultsCSV(items, filepath, unitLabel)
    gamrywb_CIC_app('__test_writeResultsCSV__', items, filepath, unitLabel);
end
