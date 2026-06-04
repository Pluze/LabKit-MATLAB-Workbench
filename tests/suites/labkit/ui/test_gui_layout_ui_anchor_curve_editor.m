function test_gui_layout_ui_anchor_curve_editor()
%TEST_GUI_LAYOUT_UI_ANCHOR_CURVE_EDITOR Verify anchor curve editor contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures()); %#ok<NASGU>

    fig = uifigure('Visible', 'off', 'Name', 'labkit_anchor_curve_editor_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    ax = uiaxes(fig);
    image(ax, zeros(40, 60, 3, 'uint8'));
    axis(ax, 'image');

    changed = false;
    editor = labkit.ui.createAnchorCurveEditor(ax, [40 60 3], ...
        struct('figure', fig, ...
        'closed', true, ...
        'style', 'Curve', ...
        'onChanged', @(~,~) markChanged()));
    editor.start([10 10; 30 12; 28 30]);
    assert(changed, 'Anchor curve editor should fire the change callback when started.');
    points = editor.getPoints();
    assert(isequal(size(points), [3 2]), 'Anchor curve editor should preserve anchor points.');
    curve = editor.curvePoints();
    assert(~isempty(curve), 'Anchor curve editor should generate display curve points.');
    editor.setStyle('Straight lines');
    curve = editor.curvePoints();
    assert(isequal(curve(1, :), curve(end, :)), ...
        'Closed straight-line editor curves should end at the first point.');
    editor.setStyle('Curve');
    editor.setPoints([10 10; 40 10; 40 30; 10 30]);
    editor.insertPoint([25 10]);
    points = editor.getPoints();
    assert(isequal(size(points), [5 2]) && isequal(points(2, :), [25 10]), ...
        'Anchor curve editor should insert new anchors into the nearest displayed curve segment.');
    twoPointEditor = labkit.ui.createAnchorCurveEditor(ax, [40 60 3], ...
        struct('figure', fig, 'closed', false, 'style', 'Straight lines', 'maxPoints', 2));
    twoPointEditor.start([5 5; 20 5]);
    twoPointEditor.insertPoint([30 5]);
    assert(isequal(size(twoPointEditor.getPoints()), [2 2]), ...
        'Anchor curve editor should enforce maxPoints for two-anchor tools.');
    openEditor = labkit.ui.createAnchorCurveEditor(ax, [40 60 3], ...
        struct('figure', fig, 'closed', false, 'style', 'Straight lines'));
    openEditor.start([10 10; 40 30]);
    openEditor.insertPoint([25 20]);
    points = openEditor.getPoints();
    assert(isequal(points(2, :), [25 20]), ...
        'Open anchor editor should insert points that are close to an existing segment.');
    spiralEditor = labkit.ui.createAnchorCurveEditor(ax, [60 70 3], ...
        struct('figure', fig, 'closed', false, 'style', 'Straight lines'));
    spiralEditor.start([20 20; 55 20; 55 55; 35 55; 35 35; 48 35]);
    spiralEditor.insertPoint([48 45]);
    points = spiralEditor.getPoints();
    assert(isequal(points(end, :), [48 45]), ...
        'Open anchor editor should extend nearby endpoints instead of inserting into an inner spiral segment.');
    crossingEditor = labkit.ui.createAnchorCurveEditor(ax, [100 120 3], ...
        struct('figure', fig, 'closed', false, 'style', 'Straight lines'));
    crossingEditor.start([10 10; 60 10; 60 80; 80 80; 80 70]);
    ax.XLim = [0.5 500.5];
    ax.YLim = [0.5 120.5];
    crossingEditor.insertPoint([45 65]);
    points = crossingEditor.getPoints();
    assert(isequal(points(3, :), [45 65]) && isequal(size(points), [6 2]), ...
        'Open anchor editor should insert correction points when endpoint extension would self-intersect.');
    editor.undoLast();
    assert(isequal(size(editor.getPoints()), [4 2]), ...
        'Anchor curve editor should remove the last anchor.');
    editor.clearPoints();
    assert(isempty(editor.getPoints()), 'Anchor curve editor should clear anchors.');

    function markChanged()
        changed = true;
    end
end
