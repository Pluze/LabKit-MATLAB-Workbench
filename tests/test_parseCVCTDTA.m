function test_parseCVCTDTA()
%TEST_PARSECVCTDTA Verify extracted CV/CT parser behavior.

    demoFile = demoFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');
    [demoItem, demoStatus] = gamrywb.dta.loadFile(demoFile, "cvct");
    assert(demoStatus.ok, demoStatus.message);
    demoScanRate = demoItem.scanRate;
    demoCurves = demoItem.curves;
    demoLog = demoItem.logmsg;
    assert(abs(demoScanRate - 9.99998e-2) < 1e-12, 'Demo SCANRATE should convert from mV/s to V/s.');
    assert(~isempty(demoCurves), 'Demo CV file should contain at least one curve.');
    assert(any(contains(string(demoLog), 'Detected')), 'Demo parser log should report detected curves.');

    tmp = [tempname '.DTA'];
    cleaner = onCleanup(@() deleteIfExists(tmp));

    fid = fopen(tmp, 'w');
    assert(fid > 0, 'Failed to create temporary CV/CT DTA fixture.');
    fprintf(fid, 'EXPLAIN\n');
    fprintf(fid, 'SCANRATE\tQUANT\t2.00000E+002\tScan Rate (mV/s)\n');
    fprintf(fid, 'CURVE1\tTABLE\n');
    fprintf(fid, 'Pt\tT\tVf\tIm\n');
    fprintf(fid, '#\ts\tV vs. Ref.\tA\n');
    fprintf(fid, '0\t0.00000E+000\t-1.00000E-001\t-1.00000E-006\n');
    fprintf(fid, '1\t1.00000E+000\t0.00000E+000\t2.00000E-006\n');
    fprintf(fid, 'CURVE2\tTABLE\n');
    fprintf(fid, 'Pt\tT\tVf\tIm\n');
    fprintf(fid, '0\t0.00000E+000\t1.00000E-001\t3.00000E-006\n');
    fprintf(fid, '1\t1.00000E+000\t2.00000E-001\t4.00000E-006\n');
    fclose(fid);

    [item, status] = gamrywb.dta.loadFile(tmp, "cvct");
    assert(status.ok, status.message);
    scanRate = item.scanRate;
    curves = item.curves;
    logmsg = item.logmsg;

    assert(abs(scanRate - 0.2) < 1e-12, 'SCANRATE should convert from mV/s to V/s.');
    assert(numel(curves) == 2, 'Parser should discover both CURVE sections.');
    assert(strcmp(curves(1).name, 'CURVE1') && strcmp(curves(2).name, 'CURVE2'), 'Curve names should be preserved.');
    assert(isequal(curves(1).headers, {'Pt', 'T', 'Vf', 'Im'}), 'Headers should be parsed.');
    assert(isequal(curves(1).units, {'#', 's', 'V vs. Ref.', 'A'}), 'Unit row should be parsed when present.');
    assert(isequal(curves(2).units, {'', '', '', ''}), 'Data-like unit rows should be treated as data.');
    assert(isequal(curves(1).data(:, 2), [0; 1]), 'Recorded time values should be preserved.');
    assert(isequal(curves(2).data(:, 4), [3e-6; 4e-6]), 'Second curve current values should be preserved.');
    assert(all(curves(1).numericMask), 'All fixture columns should be numeric.');
    assert(any(contains(string(logmsg), 'No separate unit line detected')), 'Parser should log data-like unit row behavior.');
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
