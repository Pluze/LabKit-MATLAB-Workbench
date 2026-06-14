classdef GuiLayoutUiScaleBarPanelTest < matlab.uitest.TestCase
    %GUILAYOUTUISCALEBARPANELTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_scale_bar_panel(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_scale_bar_panel();
        end
    end
end

function verify_gui_layout_ui_scale_bar_panel()
%TEST_GUI_LAYOUT_UI_SCALE_BAR_PANEL Verify reusable scale-bar panel contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = uifigure('Visible', 'off', 'Name', 'labkit_scale_bar_panel_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);
    ax = uiaxes(grid);
    ax.Layout.Row = 1;
    runtime = labkit.ui.tool.createRuntime(ax, struct('figure', fig));

    calls = struct('beforeEdit', 0, 'referenceEdit', 0, 'calibration', 0, 'bar', 0, 'place', 0);
    ui = labkit.ui.tool.scaleBar(grid, 2, runtime, ...
        struct('imageSize', [600 1000 3], ...
        'onBeforeReferenceEdit', @onBeforeEdit, ...
        'onReferenceEditChanged', @onReferenceEditChanged, ...
        'onCalibrationChanged', @onCalibration, ...
        'onScaleBarChanged', @onBar, ...
        'onScaleBarPlaced', @onPlace));

    assert(strcmp(ui.panel.Title, 'Scale Bar'), ...
        'Scale-bar panel should preserve the default panel title.');
    assert(ui.panel.Layout.Row == 2, ...
        'Scale-bar panel should place the panel in the requested row.');
    assert(h.sameStringCell(ui.grid.RowHeight, repmat({'fit'}, 1, 10)), ...
        'Scale-bar panel should create fit-height control rows.');
    assert(strcmp(ui.controls.measureReferenceButton.Text, 'Measure reference pixels'), ...
        'Scale-bar panel should create the reference-pixel edit button.');
    assert(h.sameStringCell(ui.controls.unitDropdown.Items, {'m', 'cm', 'mm', 'um', 'nm'}), ...
        'Scale-bar panel should preserve default units.');
    assert(h.sameStringCell(ui.controls.colorDropdown.Items, {'Black', 'White'}), ...
        'Scale-bar panel should expose black/white drawing colors.');

    assert(isnan(ui.referencePixels()), ...
        'Zero reference pixels should be reported as missing calibration.');
    assert(ui.pixelsPerUnit() == 0, ...
        'Missing reference pixels should produce zero pixels/unit.');
    assert(strcmp(ui.controls.referencePixelsReadout.Value, '-'), ...
        'Missing reference pixels should render as a dash.');

    ui.setReferencePixels(80);
    ui.controls.referenceLengthSpinner.Value = 20;
    ui.updateReadout();
    [pxPerUnit, unitName] = ui.pixelsPerUnit();
    cal = ui.calibration();
    assert(pxPerUnit == 4 && strcmp(unitName, 'm') && cal.isCalibrated, ...
        'Scale-bar panel should compute pixels per selected unit.');
    assert(strcmp(ui.controls.referencePixelsReadout.Value, '80'), ...
        'Scale-bar panel should update the reference-pixel readout.');
    assert(strcmp(ui.controls.pixelsPerUnitReadout.Value, '4 px/m'), ...
        'Scale-bar panel should update the pixels/unit readout.');

    spec = ui.scaleBarSpec();
    assert(isequal(spec.color, [0 0 0]) && strcmp(spec.colorName, 'Black'), ...
        'Default scale-bar color should be black.');
    assert(strcmp(spec.label, '1 m') && spec.pixelsPerUnit == 4, ...
        'Scale-bar spec should expose a real-unit label and calibration.');
    assert(size(spec.line, 1) == 2 && size(spec.line, 2) == 2, ...
        'Scale-bar spec should return a two-endpoint line.');

    ui.controls.colorDropdown.Value = 'White';
    ui.controls.positionDropdown.Value = 'Top left';
    ui.controls.barLengthSpinner.Value = 50;
    h.invokeCallback(ui.controls.barLengthSpinner, 'ValueChangedFcn');
    whiteSpec = ui.scaleBarSpec();
    assert(isequal(whiteSpec.color, [1 1 1]) && strcmp(whiteSpec.colorName, 'White'), ...
        'Scale-bar panel should map the White option to a white drawing color.');
    assert(strcmp(whiteSpec.position, 'Top left') && strcmp(whiteSpec.verticalAlignment, 'top'), ...
        'Scale-bar panel should preserve the selected label position.');
    assert(calls.bar == 1, ...
        'Scale-bar display callbacks should be invoked with source/event inputs.');

    h.invokeCallback(ui.controls.referenceLengthSpinner, 'ValueChangedFcn');
    h.invokeCallback(ui.controls.measureReferenceButton, 'ButtonPushedFcn');
    h.invokeCallback(ui.controls.placeButton, 'ButtonPushedFcn');
    assert(calls.calibration == 1 && calls.beforeEdit == 1 && ...
        calls.referenceEdit == 1 && calls.place == 1, ...
        'Scale-bar tool should wire calibration, reference-edit, and place callbacks.');

    ui.setEnabled(struct('hasImage', false));
    assert(strcmp(ui.controls.measureReferenceButton.Enable, 'off') && ...
        strcmp(ui.controls.placeButton.Enable, 'off'), ...
        'Scale-bar controls should disable image-dependent actions when no image is loaded.');
    h.invokeCallback(ui.controls.measureReferenceButton, 'ButtonPushedFcn');
    ui.setEnabled(struct('hasImage', true, ...
        'blockInputs', false, 'blockPlacement', true));
    assert(strcmp(ui.controls.measureReferenceButton.Text, 'Finish reference edit') && ...
        strcmp(ui.controls.referencePixelsSpinner.Enable, 'off') && ...
        strcmp(ui.controls.placeButton.Enable, 'off'), ...
        'Scale-bar controls should reflect reference-edit mode.');

    function onBeforeEdit(~, ~)
        calls.beforeEdit = calls.beforeEdit + 1;
    end

    function onReferenceEditChanged(~, ~)
        calls.referenceEdit = calls.referenceEdit + 1;
    end

    function onCalibration(~, ~)
        calls.calibration = calls.calibration + 1;
    end

    function onBar(~, ~)
        calls.bar = calls.bar + 1;
    end

    function onPlace(~, ~)
        calls.place = calls.place + 1;
    end
end
