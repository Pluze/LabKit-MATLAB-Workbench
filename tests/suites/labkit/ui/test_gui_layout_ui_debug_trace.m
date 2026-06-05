function test_gui_layout_ui_debug_trace()
%TEST_GUI_LAYOUT_UI_DEBUG_TRACE Verify GUI callback instrumentation for debug logs.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures()); %#ok<NASGU>

    checkDefaultInstrumentationSkipsScroll(h);
    checkExplicitInstrumentation(h);
end

function checkDefaultInstrumentationSkipsScroll(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_debug_default_trace_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [1 1]);

    buttonCalls = 0;
    scrollFcn = @(~,~) setappdata(fig, 'scrollCalled', true);
    fig.WindowScrollWheelFcn = scrollFcn;
    btnAction = uibutton(grid, 'Text', 'Default action', ...
        'ButtonPushedFcn', @onAction);

    debug = labkit.ui.createAppDebugLog('probe_app', struct());
    count = debug.instrumentFigure(fig);
    assert(count >= 1, 'Default debug instrumentation should wrap component callbacks.');
    assert(isequal(fig.WindowScrollWheelFcn, scrollFcn), ...
        'Default debug instrumentation should not wrap figure scroll callbacks.');

    h.invokeCallback(btnAction, 'ButtonPushedFcn');
    lines = string(debug.getLog());
    assert(buttonCalls == 1, 'Default instrumentation should call the original component callback.');
    assert(any(contains(lines, 'Default action')), ...
        'Default instrumentation should trace component callbacks.');
    assert(~any(contains(lines, 'WindowScrollWheelFcn')), ...
        'Default instrumentation should not add scroll traces while users read logs.');

    function onAction(varargin) %#ok<INUSD>
        buttonCalls = buttonCalls + 1;
    end
end

function checkExplicitInstrumentation(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_debug_trace_probe');
    cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
    grid = uigridlayout(fig, [2 1]);

    buttonCalls = 0;
    cellCallbackArg = "";
    btnAction = uibutton(grid, 'Text', 'Action', ...
        'ButtonPushedFcn', @onAction);
    btnAction.Layout.Row = 1;
    btnCell = uibutton(grid, 'Text', 'Cell action', ...
        'ButtonPushedFcn', {@onCellAction, 'extra'});
    btnCell.Layout.Row = 2;

    debug = labkit.ui.createAppDebugLog('probe_app', struct());
    count = debug.instrumentFigure(fig, ...
        struct('callbackProperties', {{'ButtonPushedFcn'}}));
    assert(count == 2, 'Debug instrumentation should wrap both button callbacks.');

    secondCount = debug.instrumentFigure(fig, ...
        struct('callbackProperties', {{'ButtonPushedFcn'}}));
    assert(secondCount == 0, 'Debug instrumentation should not wrap callbacks twice.');

    h.invokeCallback(btnAction, 'ButtonPushedFcn');
    h.invokeCallback(btnCell, 'ButtonPushedFcn');

    lines = string(debug.getLog());
    assert(buttonCalls == 1, 'Instrumented function-handle callbacks should call the original callback.');
    assert(cellCallbackArg == "extra", 'Instrumented cell callbacks should preserve extra callback arguments.');
    assert(any(contains(lines, 'BEGIN ButtonPushedFcn') & contains(lines, '"Action"')), ...
        'Instrumented callbacks should trace the control label.');
    assert(any(contains(lines, 'BEGIN ButtonPushedFcn') & contains(lines, 'onAction')), ...
        'Instrumented callbacks should trace the original callback function name.');
    assert(any(contains(lines, 'BEGIN ButtonPushedFcn') & contains(lines, '"Cell action"')), ...
        'Instrumented cell callbacks should trace the cell-callback control label.');
    assert(any(contains(lines, 'END ButtonPushedFcn') & contains(lines, '"Cell action"')), ...
        'Instrumented cell callbacks should trace END messages.');

    disabled = labkit.ui.createAppDebugLog('probe_app', struct('traceEnabled', false));
    disabledCount = disabled.instrumentFigure(fig, ...
        struct('callbackProperties', {{'ButtonPushedFcn'}}));
    assert(disabledCount == 0, 'traceEnabled=false should skip GUI instrumentation.');

    fig2 = uifigure('Visible', 'off', 'Name', 'labkit_debug_explicit_scroll_probe');
    cleaner2 = onCleanup(@() delete(fig2)); %#ok<NASGU>
    scrollCalls = 0;
    fig2.WindowScrollWheelFcn = @onScroll;
    explicitDebug = labkit.ui.createAppDebugLog('probe_app', struct());
    scrollCount = explicitDebug.instrumentFigure(fig2, ...
        struct('callbackProperties', "WindowScrollWheelFcn"));
    assert(scrollCount == 1, ...
        'Explicit debug instrumentation should still be able to wrap scroll callbacks.');
    fig2.WindowScrollWheelFcn(fig2, []);
    scrollLines = string(explicitDebug.getLog());
    assert(scrollCalls == 1 && any(contains(scrollLines, 'WindowScrollWheelFcn')), ...
        'Explicit scroll instrumentation should trace and call the original scroll callback.');

    function onAction(varargin) %#ok<INUSD>
        buttonCalls = buttonCalls + 1;
    end

    function onCellAction(varargin)
        cellCallbackArg = string(varargin{end});
    end

    function onScroll(varargin) %#ok<INUSD>
        scrollCalls = scrollCalls + 1;
    end
end
