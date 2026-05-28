function test_chronoOverlayExport()
%TEST_CHRONOOVERLAYEXPORT Verify chrono overlay export table behavior.

    item1 = struct();
    item1.name = 'A.DTA';
    item1.tAligned = [0; 1];
    item1.Vf = [10; 20];
    item1.Im = [1; 2];

    item2 = struct();
    item2.name = 'B 1.DTA';
    item2.tAligned = [0.5; 1.5];
    item2.Vf = [100; 300];
    item2.Im = [-1; -3];

    T = gamrywb.io.buildChronoOverlayExportTable([item1 item2]);
    safe1 = gamrywb.util.sanitizeFieldName(item1.name);
    safe2 = gamrywb.util.sanitizeFieldName(item2.name);
    v1 = ['V_' safe1];
    i1 = ['I_' safe1];
    v2 = ['V_' safe2];
    i2 = ['I_' safe2];

    assert(isequal(T.Properties.VariableNames, [{'TimeGapCenterAligned_s'}, {v1}, {i1}, {v2}, {i2}]), ...
        'Export table variable names should preserve legacy column naming.');
    assert(isequal(T.TimeGapCenterAligned_s, [0; 0.5; 1; 1.5]), ...
        'Export table should use the sorted union of aligned time vectors.');
    assert(abs(T.(v1)(2) - 15) < 1e-12, 'First voltage column should be linearly interpolated.');
    assert(abs(T.(i1)(2) - 1.5) < 1e-12, 'First current column should be linearly interpolated.');
    assert(isnan(T.(v1)(4)) && isnan(T.(i1)(4)), 'First item should be NaN outside its time range.');
    assert(abs(T.(v2)(3) - 200) < 1e-12, 'Second voltage column should be linearly interpolated.');
    assert(abs(T.(i2)(3) + 2) < 1e-12, 'Second current column should be linearly interpolated.');
    assert(isnan(T.(v2)(1)) && isnan(T.(i2)(1)), 'Second item should be NaN outside its time range.');

    item3 = struct();
    item3.name = 'C.DTA';
    item3.tAligned_s = [2; 3];
    item3.Vf_V = [5; 7];
    item3.Im_A = [0.1; 0.3];
    T2 = gamrywb.io.buildChronoOverlayExportTable(item3);
    safe3 = gamrywb.util.sanitizeFieldName(item3.name);
    assert(isequal(T2.TimeGapCenterAligned_s, [2; 3]), ...
        'Export table should accept normalized aligned time fields.');
    assert(isequal(T2.(['V_' safe3]), [5; 7]), ...
        'Export table should accept normalized voltage fields.');

    tmp = [tempname '.csv'];
    cleaner = onCleanup(@() deleteIfExists(tmp));
    gamrywb.io.exportTableCSV(T, tmp);
    txt = fileread(tmp);
    assert(startsWith(string(txt), strjoin(T.Properties.VariableNames, ',')), ...
        'CSV header should match table variable names.');
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
