function test_plotXY()
%TEST_PLOTXY Verify prepared X/Y plotting helper behavior.

    curve = struct();
    curve.name = 'CURVE1';
    curve.headers = {'T', 'Vf', 'Im'};
    curve.units = {'s', 'V', 'A'};
    curve.numericMask = [true true true];
    curve.data = [0 0.1 NaN; 1 0.2 -1; 2 NaN 2; 3 0.4 3];

    [x, y, xname, yname] = gamrywb.data.getCurveXY(curve, 'T', 'Vf');
    assert(isequal(x, [0; 1; 3]), 'getCurveXY should remove rows with NaN X/Y.');
    assert(isequal(y, [0.1; 0.2; 0.4]), 'getCurveXY should preserve selected Y values.');
    assert(strcmp(xname, 'T') && strcmp(yname, 'Vf'), 'getCurveXY should return selected header names.');

    [badX, badY] = gamrywb.data.getCurveXY(curve, 't', 'Vf');
    assert(isempty(badX) && isempty(badY), 'getCurveXY should preserve legacy exact-case column selection.');

    fig = figure('Visible', 'off');
    cleaner = onCleanup(@() closeIfValid(fig));
    ax = axes(fig);

    opts = struct('holdPlot', false, 'showGrid', true, 'lineWidth', 1.2);
    labels = struct('title', curve.name, 'x', xname, 'y', yname);
    info = gamrywb.ui.plotXY(ax, x, y, labels, opts);
    assert(info.ok, info.message);
    assert(isequal(info.x, x), 'plotXY should plot prepared X values.');
    assert(isequal(info.y, y), 'plotXY should plot prepared Y values.');
    assert(strcmp(info.xName, 'T') && strcmp(info.yName, 'Vf'), 'plotXY should report axis names.');

    lines = findobj(ax, 'Type', 'line');
    assert(numel(lines) == 1, 'plotXY should add one data line.');
    assert(abs(lines(1).LineWidth - 1.2) < 1e-12, 'Line width should match legacy default.');
    assert(strcmp(ax.Title.String, 'CURVE1'), 'Plot title should use curve name.');
    assert(strcmp(ax.XLabel.String, 'T'), 'X label should use selected header.');
    assert(strcmp(ax.YLabel.String, 'Vf'), 'Y label should use selected header.');

    info2 = gamrywb.ui.plotXY(ax, [], y, labels, opts);
    assert(~info2.ok, 'Invalid X/Y selection should fail without throwing.');
    assert(strcmp(info2.message, 'invalid X/Y'), 'Invalid selection message should be stable.');
end

function closeIfValid(fig)
    if isvalid(fig)
        close(fig);
    end
end
