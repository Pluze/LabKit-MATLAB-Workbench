function test_eisOverlayExport()
%TEST_EISOVERLAYEXPORT Verify EIS item schema and export/plot contracts.

    root = testRepoRoot();
    fixture = dtaFixturePath('eis_potentiostatic_zcurve.DTA');

    [item, status] = labkit.dta.loadFile(fixture, "eis");
    assert(status.ok, status.message);
    assert(strcmp(item.type, "eis"), 'EIS item type should be normalized.');
    assert(strcmp(item.name, 'eis_potentiostatic_zcurve.DTA'), 'EIS item name should use fixture file name.');
    assert(strcmp(item.message, 'Using table: ZCURVE'), 'EIS item message should preserve ZCURVE selection wording.');
    assert(isequal(item.zcurve, item.curve), 'EIS item should expose a normalized zcurve alias.');
    assert(numel(item.Freq) == item.n, 'EIS item n should match filtered data length.');
    assert(abs(item.Freq(1) - 0.999041) < 1e-12, 'EIS item Freq should match fixture.');
    assert(abs(item.Zreal(1) - 138.7798) < 1e-12, 'EIS item Zreal should match fixture.');
    assert(abs(item.negZimag(1) - 2.786225) < 1e-12, 'EIS item negZimag should be derived from Zimag.');
    assert(~item.freqDesc, 'Fixture frequency order should preserve low-to-high/mixed summary behavior.');
    assert(isstruct(item.analysis) && isempty(fieldnames(item.analysis)), ...
        'EIS item should initialize an empty analysis struct.');
    assertClose(item.point, item.Pt, 'EIS normalized point alias');
    assertClose(item.time_s, item.Time, 'EIS normalized time alias');
    assertClose(item.freq_Hz, item.Freq, 'EIS normalized frequency alias');
    assertClose(item.Zreal_ohm, item.Zreal, 'EIS normalized Zreal alias');
    assertClose(item.Zimag_ohm, item.Zimag, 'EIS normalized Zimag alias');
    assertClose(item.negZimag_ohm, item.negZimag, 'EIS normalized -Zimag alias');
    assertClose(item.Zmod_ohm, item.Zmod, 'EIS normalized Zmod alias');
    assertClose(item.Zphz_deg, item.Zphz, 'EIS normalized Zphz alias');
    assertClose(item.Idc_A, item.Idc, 'EIS normalized Idc alias');
    assertClose(item.Vdc_V, item.Vdc, 'EIS normalized Vdc alias');

    appFile = appEntryFile(root, 'labkit_EIS_app');
    source = fileread(appFile);
    assert(contains(source, '''Freq (Hz)''') && contains(source, '''Zreal (ohm)''') && ...
        contains(source, '''-Zimag (ohm)'''), ...
        'EIS app should preserve legacy axis labels.');
    assert(contains(source, 'RowIndex') && contains(source, 'X_%s_%s') && contains(source, 'Y_%s_%s'), ...
        'EIS app should preserve legacy export column naming logic.');
    assert(contains(source, 'axis(ax, ''equal'')'), ...
        'EIS app should preserve equal-axis Nyquist plot behavior.');
end
