function test_parseChronoDTA()
%TEST_PARSECHRONODTA Verify extracted chrono DTA parser and accessors.

    root = fileparts(fileparts(mfilename('fullpath')));

    filepaths = gamrywb.io.findDTAFilesRecursive(fullfile(root, 'demo'));
    assert(numel(filepaths) == 3, 'findDTAFilesRecursive should find the three demo DTA files.');
    assert(all(endsWith(lower(string(filepaths)), '.dta')), 'findDTAFilesRecursive should return only DTA files.');

    tmp = [tempname '.DTA'];
    cleaner = onCleanup(@() deleteIfExists(tmp));

    fid = fopen(tmp, 'w');
    assert(fid > 0, 'Failed to create temporary DTA fixture.');
    fprintf(fid, 'EXPLAIN\n');
    fprintf(fid, 'AREA\tQUANT\t2.01000E+000\tElectrode Area\n');
    fprintf(fid, 'SAMPLETIME\tQUANT\t1.00000E-003\tSample Time\n');
    fprintf(fid, 'ISTEP1\tQUANT\t-1.00000E-003\tStep current\n');
    fprintf(fid, 'TSTEP1\tQUANT\t1.00000E-001\tStep time\n');
    fprintf(fid, 'ISTEP2\tQUANT\t1.00000E-003\tStep current\n');
    fprintf(fid, 'TSTEP2\tQUANT\t1.00000E-001\tStep time\n');
    fprintf(fid, 'CURVE\tTABLE\tDATA\n');
    fprintf(fid, 'Pt\tT\tVf\tIm\n');
    fprintf(fid, '#\ts\tV vs. Ref.\tA\n');
    fprintf(fid, '0\t0.00000E+000\t1.00000E-001\t-1.00000E-003\n');
    fprintf(fid, '1\t1.00000E-003\t1.10000E-001\t-1.00000E-003\n');
    fprintf(fid, '2\t2.00000E-003\t1.20000E-001\t1.00000E-003\n');
    fclose(fid);

    [meta, tables, logmsg] = gamrywb.io.parseChronoDTA(tmp);

    assert(abs(meta.area_cm2 - 2.01) < 1e-12, 'AREA metadata should be parsed.');
    assert(abs(meta.sampleTime_s - 1e-3) < 1e-12, 'SAMPLETIME metadata should be parsed.');
    assert(numel(meta.steps) == 2, 'ISTEP/TSTEP metadata should produce two steps.');
    assert(meta.steps(1).I == -1e-3 && meta.steps(2).I == 1e-3, 'Step current values should be preserved.');
    assert(numel(tables) == 1 && strcmp(tables(1).name, 'CURVE'), 'CURVE table should be parsed.');
    assert(any(contains(string(logmsg), 'Table CURVE parsed: 3 rows x 4 cols.')), 'Parser log should include table dimensions.');

    [curve, ok, msg] = gamrywb.data.getMainCurve(tables);
    assert(ok, msg);
    assert(strcmp(msg, 'Using table: CURVE'), 'Main curve message should match legacy wording.');

    t = gamrywb.data.getColumn(curve, 'T');
    vf = gamrywb.data.getColumn(curve, 'Vf');
    im = gamrywb.data.getColumn(curve, 'im');
    missing = gamrywb.data.getColumn(curve, 'MissingColumn');

    assert(isequal(t(:), [0; 1e-3; 2e-3]), 'T column should match fixture values.');
    assert(isequal(vf(:), [0.1; 0.11; 0.12]), 'Vf column should match fixture values.');
    assert(isequal(im(:), [-1e-3; -1e-3; 1e-3]), 'Im column should be case-insensitive.');
    assert(isempty(missing), 'Missing columns should return empty.');
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
