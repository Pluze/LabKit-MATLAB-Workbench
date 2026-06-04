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
    fig2 = uifigure('Visible', 'off', 'Name', 'labkit_anchor_curve_editor_callback_probe');
    cleaner2 = onCleanup(@() delete(fig2)); %#ok<NASGU>
    ax2 = uiaxes(fig2);
    image(ax2, zeros(40, 60, 3, 'uint8'));
    axis(ax2, 'image');
    baseScroll2 = @(~,~) setappdata(fig2, 'baseScrollCalled', true);
    fig2.WindowScrollWheelFcn = baseScroll2;
    scrollEditor = labkit.ui.createAnchorCurveEditor(ax2, [40 60 3], ...
        struct('figure', fig2, 'closed', false, 'style', 'Straight lines'));
    scrollEditor.start([5 5; 20 20]);
    assert(~isempty(fig2.WindowScrollWheelFcn), ...
        'Active anchor editor should install scroll-wheel zoom.');
    editorLines = findobj(ax2, 'Type', 'Line');
    assert(~isempty(editorLines) && all(strcmp({editorLines.HitTest}, 'on')), ...
        'Active anchor editor graphics should receive pointer events.');
    scrollEditor.setActive(false);
    assert(isequal(fig2.WindowScrollWheelFcn, baseScroll2), ...
        'Inactive anchor editor should restore the prior scroll-wheel callback.');
    editorLines = findobj(ax2, 'Type', 'Line');
    assert(~isempty(editorLines) && all(strcmp({editorLines.HitTest}, 'off')), ...
        'Inactive anchor editor graphics should not intercept pointer events.');
    fig3 = uifigure('Visible', 'off', 'Name', 'labkit_anchor_curve_editor_mutex_probe');
    cleaner3 = onCleanup(@() delete(fig3)); %#ok<NASGU>
    ax3 = uiaxes(fig3);
    image(ax3, zeros(40, 60, 3, 'uint8'));
    axis(ax3, 'image');
    baseScroll3 = @(~,~) setappdata(fig3, 'baseScrollCalled', true);
    fig3.WindowScrollWheelFcn = baseScroll3;
    firstEditor = labkit.ui.createAnchorCurveEditor(ax3, [40 60 3], ...
        struct('figure', fig3, 'closed', false, 'style', 'Straight lines'));
    secondEditor = labkit.ui.createAnchorCurveEditor(ax3, [40 60 3], ...
        struct('figure', fig3, 'closed', false, 'style', 'Straight lines'));
    firstEditor.start([5 5; 20 20]);
    secondEditor.start([8 8; 24 24]);
    assert(~isempty(fig3.WindowScrollWheelFcn), ...
        'A later active anchor editor should own the axes scroll callback.');
    firstEditor.setActive(false);
    assert(~isempty(fig3.WindowScrollWheelFcn), ...
        'A deactivated peer editor should not clear the active editor callback.');
    secondEditor.setActive(false);
    assert(isequal(fig3.WindowScrollWheelFcn, baseScroll3), ...
        'The active editor should restore the prior scroll callback when stopped.');

    function markChanged()
        changed = true;
    end
end
