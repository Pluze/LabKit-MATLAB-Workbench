function test_parseEISDTA()
%TEST_PARSEEISDTA Verify extracted EIS parser and ZCURVE accessors.

    tmp = [tempname '.DTA'];
    cleaner = onCleanup(@() deleteIfExists(tmp));

    fid = fopen(tmp, 'w');
    assert(fid > 0, 'Failed to create temporary EIS DTA fixture.');
    fprintf(fid, 'EXPLAIN\n');
    fprintf(fid, 'TAG\tLABEL\tEIS\tTechnique\n');
    fprintf(fid, 'TITLE\tLABEL\tSynthetic EIS\tTitle\n');
    fprintf(fid, 'AREA\tQUANT\t3.50000E-002\tElectrode Area\n');
    fprintf(fid, 'ZCURVE\tTABLE\n');
    fprintf(fid, 'Pt\tTime\tFreq\tZreal\tZimag\tZmod\tZphz\tIdc\tVdc\n');
    fprintf(fid, '#\ts\tHz\tohm\tohm\tohm\tdeg\tA\tV\n');
    fprintf(fid, '0\t0.00000E+000\t1.00000E+003\t1.00000E+001\t-5.00000E+000\t1.11803E+001\t-2.65651E+001\t1.00000E-006\t2.00000E-001\n');
    fprintf(fid, '1\t1.00000E+000\t1.00000E+002\t1.10000E+001\t-4.00000E+000\t1.17047E+001\t-1.99836E+001\t2.00000E-006\t2.10000E-001\n');
    fclose(fid);

    [meta, tables, logmsg] = gamrywb.io.parseEISDTA(tmp);

    assert(strcmp(meta.tag, 'EIS'), 'TAG metadata should be parsed.');
    assert(strcmp(meta.title, 'Synthetic EIS'), 'TITLE metadata should be parsed.');
    assert(abs(meta.area_cm2 - 0.035) < 1e-12, 'AREA metadata should be parsed.');
    assert(numel(tables) == 1 && strcmp(tables(1).name, 'ZCURVE'), 'ZCURVE table should be parsed.');
    assert(any(contains(string(logmsg), 'Table ZCURVE parsed: 2 rows x 9 cols.')), 'Parser log should include table dimensions.');

    [curve, ok, msg] = gamrywb.data.getZCurve(tables);
    assert(ok, msg);
    assert(strcmp(msg, 'Using table: ZCURVE'), 'ZCURVE message should match legacy wording.');

    freq = gamrywb.data.getColumn(curve, 'Freq');
    zreal = gamrywb.data.getColumn(curve, 'Zreal');
    zimag = gamrywb.data.getColumn(curve, 'zimag');

    assert(isequal(freq(:), [1000; 100]), 'Freq column should match fixture values.');
    assert(isequal(zreal(:), [10; 11]), 'Zreal column should match fixture values.');
    assert(isequal(zimag(:), [-5; -4]), 'Zimag column should be case-insensitive.');

    fallback = struct();
    fallback.name = 'OTHER';
    fallback.headers = {'Freq', 'Zreal', 'Zimag'};
    fallback.units = {'Hz', 'ohm', 'ohm'};
    fallback.data = [1 2 3];
    fallback.numericMask = [true true true];
    [curve2, ok2, msg2] = gamrywb.data.getZCurve(fallback);
    assert(ok2 && strcmp(curve2.name, 'OTHER'), msg2);
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
