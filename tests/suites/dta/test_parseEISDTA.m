function test_parseEISDTA()
%TEST_PARSEEISDTA Verify extracted EIS parser and ZCURVE accessors.

    fixture = demoFixturePath('eis_potentiostatic_zcurve.DTA');

    [item, status] = labkit.dta.loadFile(fixture, "eis");
    assert(status.ok, status.message);
    meta = item.meta;
    tables = item.tables;
    logmsg = item.logmsg;

    assert(strcmp(meta.tag, ''), 'Two-token TAG metadata should preserve legacy empty-tag behavior.');
    assert(strcmp(meta.title, 'Potentiostatic EIS'), 'TITLE metadata should be parsed from EIS fixture.');
    assert(abs(meta.area_cm2 - 1.76) < 1e-12, 'AREA metadata should be parsed from EIS fixture.');
    assert(any(strcmp({tables.name}, 'ZCURVE')), 'ZCURVE table should be parsed.');
    assert(any(contains(string(logmsg), 'Table ZCURVE parsed:')), 'Parser log should include ZCURVE dimensions.');

    [curve, ok, msg] = labkit.dta.getZCurve(tables);
    assert(ok, msg);
    assert(strcmp(msg, 'Using table: ZCURVE'), 'ZCURVE message should match legacy wording.');

    freq = labkit.dta.getColumn(curve, 'Freq');
    zreal = labkit.dta.getColumn(curve, 'Zreal');
    zimag = labkit.dta.getColumn(curve, 'zimag');

    assert(numel(freq) > 10, 'EIS fixture should contain multiple impedance points.');
    assert(abs(freq(1) - 0.999041) < 1e-12, 'Freq column should match EIS fixture values.');
    assert(abs(zreal(1) - 138.7798) < 1e-12, 'Zreal column should match EIS fixture values.');
    assert(abs(zimag(1) + 2.786225) < 1e-12, 'Zimag column should be case-insensitive and match fixture values.');

    fallback = struct();
    fallback.name = 'OTHER';
    fallback.headers = {'Freq', 'Zreal', 'Zimag'};
    fallback.units = {'Hz', 'ohm', 'ohm'};
    fallback.data = [1 2 3];
    fallback.numericMask = [true true true];
    [curve2, ok2, msg2] = labkit.dta.getZCurve(fallback);
    assert(ok2 && strcmp(curve2.name, 'OTHER'), msg2);
end
