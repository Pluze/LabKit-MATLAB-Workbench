function test_eisOverlayExport()
%TEST_EISOVERLAYEXPORT Verify package-backed EIS overlay/export helpers.

    root = fileparts(fileparts(mfilename('fullpath')));
    fixture = fullfile(root, 'demo', 'eis_potentiostatic_zcurve.DTA');

    item = gamrywb.data.makeEISItem(fixture);
    assert(strcmp(item.name, 'eis_potentiostatic_zcurve.DTA'), 'EIS item name should use fixture file name.');
    assert(strcmp(item.message, 'Using table: ZCURVE'), 'EIS item message should preserve ZCURVE selection wording.');
    assert(numel(item.Freq) == item.n, 'EIS item n should match filtered data length.');
    assert(abs(item.Freq(1) - 0.999041) < 1e-12, 'EIS item Freq should match fixture.');
    assert(abs(item.Zreal(1) - 138.7798) < 1e-12, 'EIS item Zreal should match fixture.');
    assert(abs(item.negZimag(1) - 2.786225) < 1e-12, 'EIS item negZimag should be derived from Zimag.');
    assert(~item.freqDesc, 'Fixture frequency order should preserve low-to-high/mixed summary behavior.');

    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Freq (Hz)'), item.Freq, 'Freq axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'log10(Freq)'), log10(item.Freq), 'log Freq axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Time (s)'), item.Time, 'Time axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Point #'), item.Pt, 'Point axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Zreal (ohm)'), item.Zreal, 'Zreal axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Zimag (ohm)'), item.Zimag, 'Zimag axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, '-Zimag (ohm)'), item.negZimag, 'Negative Zimag axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Zmod (ohm)'), item.Zmod, 'Zmod axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Zphz (deg)'), item.Zphz, 'Zphz axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Idc (A)'), item.Idc, 'Idc axis');
    assertClose(gamrywb.analysis.valuesForEISAxis(item, 'Vdc (V)'), item.Vdc, 'Vdc axis');

    synthetic = item;
    synthetic.name = 'A.DTA';
    synthetic.Freq = [-10; 1; 10];
    synthetic.Time = [0; 1; 2];
    synthetic.Pt = [0; 1; 2];
    synthetic.Zreal = [1; NaN; 3];
    synthetic.Zimag = [-2; -3; -4];
    synthetic.negZimag = -synthetic.Zimag;
    synthetic.Zmod = [2; 3; 4];
    synthetic.Zphz = [20; 30; 40];
    synthetic.Idc = [0.1; 0.2; 0.3];
    synthetic.Vdc = [0.4; 0.5; 0.6];
    synthetic.n = 3;

    T = gamrywb.io.buildEISExportTable(synthetic, 'Freq (Hz)', 'Zreal (ohm)', false, false);
    assert(isequal(T.Properties.VariableNames, {'RowIndex', 'X_freq_hz_A_DTA', 'Y_zreal_ohm_A_DTA'}), ...
        'EIS export column names should preserve legacy naming.');
    assert(isequal(T.RowIndex, [1; 2]), 'EIS export should use row index up to max filtered length.');
    assert(isequal(T.X_freq_hz_A_DTA, [-10; 10]), 'EIS export should keep finite X/Y rows.');
    assert(isequal(T.Y_zreal_ohm_A_DTA, [1; 3]), 'EIS export should keep paired finite Y rows.');

    Tlog = gamrywb.io.buildEISExportTable(synthetic, 'Freq (Hz)', 'Zreal (ohm)', true, false);
    assert(isequal(Tlog.RowIndex, 1), 'Log-X export should remove nonpositive X values.');
    assert(isequal(Tlog.X_freq_hz_A_DTA, 10), 'Log-X export should keep positive X values only.');
    assert(isequal(Tlog.Y_zreal_ohm_A_DTA, 3), 'Log-X export should keep paired Y values only.');

    fig = figure('Visible', 'off');
    cleaner = onCleanup(@() closeIfValid(fig));
    ax = axes(fig);
    opts = struct('xName', 'Zreal (ohm)', 'yName', '-Zimag (ohm)', ...
        'logX', false, 'logY', false, 'lineWidth', 1.4, 'markerSize', 6, ...
        'showMarkers', true, 'showLegend', true, 'showGrid', true);
    labels = gamrywb.plot.plotEISOverlay(ax, synthetic, opts);
    assert(isequal(labels, {'A.DTA'}), 'EIS plot labels should use item names.');
    assert(strcmp(ax.XLabel.String, 'Zreal (ohm)'), 'EIS X label should match selected axis.');
    assert(strcmp(ax.YLabel.String, '-Zimag (ohm)'), 'EIS Y label should match selected axis.');
    assert(strcmp(ax.Title.String, '-Zimag (ohm) vs Zreal (ohm) (1 file)'), ...
        'EIS plot title should preserve legacy wording.');
    assert(strcmp(ax.XScale, 'linear') && strcmp(ax.YScale, 'linear'), 'Default EIS axes should be linear.');
    assert(strcmp(ax.DataAspectRatioMode, 'manual'), 'Nyquist selection should force equal axis scaling.');

    opts.logX = true;
    opts.logY = true;
    opts.yName = 'Zmod (ohm)';
    gamrywb.plot.plotEISOverlay(ax, synthetic, opts);
    assert(strcmp(ax.XScale, 'log') && strcmp(ax.YScale, 'log'), 'Log checkboxes should set log scales.');
end

function assertClose(actual, expected, label)
    assert(isequaln(actual, expected), '%s should match expected values.', label);
end

function closeIfValid(fig)
    if isvalid(fig)
        close(fig);
    end
end
