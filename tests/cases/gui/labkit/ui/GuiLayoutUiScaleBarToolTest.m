classdef GuiLayoutUiScaleBarToolTest < matlab.uitest.TestCase
    %GUILAYOUTUISCALEBARTOOLTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_scale_bar_tool(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_scale_bar_tool();
        end
    end
end

function verify_gui_layout_ui_scale_bar_tool()
%TEST_GUI_LAYOUT_UI_SCALE_BAR_TOOL Verify high-level scale-bar tool contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = uifigure('Visible', 'off', 'Name', 'labkit_scale_bar_tool_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);
    ax = uiaxes(grid);
    ax.Layout.Row = 1;
    hold(ax, 'on');
    calls = struct('beforeEdit', 0, 'edit', 0, 'calibration', 0, ...
        'bar', 0, 'placed', 0, 'error', 0);
    traceMessages = {};
    runtime = labkit.ui.tool.createRuntime(ax, ...
        struct('figure', fig, 'onTrace', @captureTrace));
    tool = labkit.ui.tool.scaleBar(grid, 2, runtime, ...
        struct('onBeforeReferenceEdit', @onBeforeEdit, ...
        'onReferenceEditChanged', @onEdit, ...
        'onCalibrationChanged', @onCalibration, ...
        'onScaleBarChanged', @onBar, ...
        'onScaleBarPlaced', @onPlaced, ...
        'onError', @onError, ...
        'onTrace', @captureTrace));
    tool.setImageSize([120 240 3]);

    bg = imagesc(ax, rand(120, 240));
    ax.XLim = [30 150];
    ax.YLim = [20 100];
    zoomXLim = ax.XLim;
    zoomYLim = ax.YLim;
    tool.setBackground(bg);
    tool.setReferencePixels(80);
    tool.controls.referenceLengthSpinner.Value = 20;
    tool.controls.unitDropdown.Value = 'mm';
    h.invokeCallback(tool.controls.unitDropdown, 'ValueChangedFcn');

    cal = tool.calibration();
    assert(cal.isCalibrated && cal.pixelsPerUnit == 4 && strcmp(cal.unit, 'mm'), ...
        'Scale-bar tool should expose the shared calibration model.');
    callbackCount = calls.calibration;
    restored = labkit.ui.tool.scaleBarCalibration(150, 30, "um", ...
        struct('defaultUnit', 'um', 'referenceLine', [10 12; 160 12]));
    tool.setCalibration(restored);
    restoredCal = tool.calibration();
    assert(restoredCal.isCalibrated && restoredCal.pixelsPerUnit == 5 && ...
        strcmp(restoredCal.unit, 'um') && isequal(restoredCal.referenceLine, [10 12; 160 12]), ...
        'Scale-bar tool should restore a saved per-image calibration without losing endpoints.');
    assert(calls.calibration == callbackCount, ...
        'Programmatic scale-bar calibration restore should not fire app calibration callbacks.');
    tool.setCalibration(cal);

    tool.controls.barLengthSpinner.Value = 10;
    h.invokeCallback(tool.controls.barLengthSpinner, 'ValueChangedFcn');
    spec = tool.scaleBarSpec();
    assert(strcmp(spec.label, '10 mm') && spec.pixelsPerUnit == 4, ...
        'Scale-bar tool should build the current scale-bar spec.');

    h.invokeCallback(tool.controls.placeButton, 'ButtonPushedFcn');
    assert(tool.hasScaleBar() && calls.placed == 1, ...
        'Place button should store a placed scale-bar spec.');
    handles = tool.renderOverlay(ax);
    assert(isstruct(handles) && isvalid(handles.line) && isvalid(handles.label), ...
        'Scale-bar tool should render a stored overlay.');

    h.invokeCallback(tool.controls.measureReferenceButton, 'ButtonPushedFcn');
    assert(tool.isReferenceEditActive() && calls.beforeEdit == 1, ...
        'Measure reference button should enter reference edit mode.');
    assert(isequal(ax.XLim, zoomXLim) && isequal(ax.YLim, zoomYLim), ...
        'Scale-bar reference editing should preserve the current zoom when it starts.');
    traceText = string(traceMessages);
    assert(any(contains(traceText, 'scaleBarTool: Measure reference button starting edit')) && ...
        any(contains(traceText, 'anchorCurveEditor: setPoints')) && ...
        any(contains(traceText, 'imageAxesRuntime: activate session anchorCurveEditor')), ...
        'Scale-bar reference editing should trace tool, editor, and runtime activation.');
    h.invokeCallback(tool.controls.measureReferenceButton, 'ButtonPushedFcn');
    assert(~tool.isReferenceEditActive(), ...
        'Measure reference button should finish reference edit mode when active.');
    assert(isequal(ax.XLim, zoomXLim) && isequal(ax.YLim, zoomYLim), ...
        'Scale-bar reference editing should preserve zoom when it finishes.');
    traceText = string(traceMessages);
    assert(any(contains(traceText, 'scaleBarTool: Measure reference button finishing active edit')) && ...
        any(contains(traceText, 'imageAxesRuntime: deactivate session anchorCurveEditor active=1')), ...
        'Scale-bar reference editing should trace the second-click finish path.');

    fig2 = uifigure('Visible', 'off', 'Name', 'labkit_scale_bar_tool_background_probe');
    cleaner2 = onCleanup(@() delete(fig2));
    grid2 = uigridlayout(fig2, [2 1]);
    ax2 = uiaxes(grid2);
    ax2.Layout.Row = 1;
    bg2 = imagesc(ax2, rand(40, 80));
    runtime2 = labkit.ui.tool.createRuntime(ax2, struct('figure', fig2));
    tool2 = labkit.ui.tool.scaleBar(grid2, 2, runtime2, ...
        struct('onError', @onError));
    tool2.setImageSize([40 80 1]);
    h.invokeCallback(tool2.controls.measureReferenceButton, 'ButtonPushedFcn');
    assert(tool2.isReferenceEditActive(), ...
        'Scale-bar tool should enter reference edit mode without app-owned background wiring.');
    assert(strcmp(bg2.HitTest, 'on') && strcmp(bg2.PickableParts, 'visible'), ...
        'Scale-bar tool should bind the current axes image as the editable background.');
    h.invokeCallback(tool2.controls.measureReferenceButton, 'ButtonPushedFcn');
    assert(strcmp(bg2.HitTest, 'off') && strcmp(bg2.PickableParts, 'none'), ...
        'Scale-bar tool should release background hit testing when reference edit finishes.');
    tool2.delete();

    tool.delete();
    checkReferenceEditRestartDoesNotReenterRefresh(h);

    function onBeforeEdit(~, ~)
        calls.beforeEdit = calls.beforeEdit + 1;
    end

    function onEdit(~, ~)
        calls.edit = calls.edit + 1;
    end

    function onCalibration(~, ~)
        calls.calibration = calls.calibration + 1;
    end

    function onBar(~, ~)
        calls.bar = calls.bar + 1;
    end

    function onPlaced(~, ~)
        calls.placed = calls.placed + 1;
    end

    function onError(~, ~)
        calls.error = calls.error + 1;
    end

    function captureTrace(message)
        traceMessages{end+1, 1} = message;
    end
end

function checkReferenceEditRestartDoesNotReenterRefresh(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_scale_bar_tool_restart_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);
    ax = uiaxes(grid);
    ax.Layout.Row = 1;
    tool = [];
    calibrationCalls = 0;
    refreshCalls = 0;

    runtime = labkit.ui.tool.createRuntime(ax, struct('figure', fig));
    tool = labkit.ui.tool.scaleBar(grid, 2, runtime, ...
        struct('onCalibrationChanged', @onCalibration, ...
        'onError', @onError));
    tool.setImageSize([60 80 1]);
    bg = imagesc(ax, rand(60, 80));
    tool.setBackground(bg);

    h.invokeCallback(tool.controls.measureReferenceButton, 'ButtonPushedFcn');
    assert(tool.isReferenceEditActive(), ...
        'Scale-bar tool should enter reference edit mode before restart coverage.');
    h.invokeCallback(tool.controls.measureReferenceButton, 'ButtonPushedFcn');
    assert(~tool.isReferenceEditActive(), ...
        'Scale-bar tool should finish reference edit before restart coverage.');

    calibrationCalls = 0;
    refreshCalls = 0;
    h.invokeCallback(tool.controls.measureReferenceButton, 'ButtonPushedFcn');
    assert(tool.isReferenceEditActive(), ...
        'Scale-bar tool should re-enter reference edit mode.');
    assert(calibrationCalls == 0 && refreshCalls == 0, ...
        'Restarting reference edit should not emit calibration changes from internal editor sync.');
    h.invokeCallback(tool.controls.measureReferenceButton, 'ButtonPushedFcn');
    tool.delete();

    function onCalibration(~, ~)
        calibrationCalls = calibrationCalls + 1;
        if calibrationCalls > 1
            error('labkit_test:ScaleBarRefreshReentry', ...
                'Scale-bar reference restart reentered calibration refresh.');
        end
        if ~isempty(tool) && tool.isReferenceEditActive()
            refreshCalls = refreshCalls + 1;
            tool.refresh();
        end
    end

    function onError(~, ~)
    end
end
