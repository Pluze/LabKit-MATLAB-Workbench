classdef GuiLayoutUiDebugTraceTest < matlab.uitest.TestCase
    %GUILAYOUTUIDEBUGTRACETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_debug_trace(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_debug_trace();
        end
    end
end

function verify_gui_layout_ui_debug_trace()
%TEST_GUI_LAYOUT_UI_DEBUG_TRACE Verify GUI callback instrumentation for debug logs.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    checkDefaultInstrumentationSkipsScroll(h);
    checkExplicitInstrumentation(h);
    checkAttachedTextLogReceivesTraceLines(h);
    checkDiagnosticReports();
    checkFilePanelSemanticTrace();
end

function checkDefaultInstrumentationSkipsScroll(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_debug_default_trace_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [1 1]);

    buttonCalls = 0;
    scrollFcn = @(~,~) setappdata(fig, 'scrollCalled', true);
    fig.WindowScrollWheelFcn = scrollFcn;
    btnAction = uibutton(grid, 'Text', 'Default action', ...
        'ButtonPushedFcn', @onAction);

    debug = labkit.ui.debug.context('probe_app', struct());
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

    function onAction(varargin)
        buttonCalls = buttonCalls + 1;
    end
end

function checkExplicitInstrumentation(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_debug_trace_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);

    buttonCalls = 0;
    cellCallbackArg = "";
    btnAction = uibutton(grid, 'Text', 'Action', ...
        'ButtonPushedFcn', @onAction);
    btnAction.Layout.Row = 1;
    btnCell = uibutton(grid, 'Text', 'Cell action', ...
        'ButtonPushedFcn', {@onCellAction, 'extra'});
    btnCell.Layout.Row = 2;

    debug = labkit.ui.debug.context('probe_app', struct());
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

    disabled = labkit.ui.debug.context('probe_app', struct('traceEnabled', false));
    disabledCount = disabled.instrumentFigure(fig, ...
        struct('callbackProperties', {{'ButtonPushedFcn'}}));
    assert(disabledCount == 0, 'traceEnabled=false should skip GUI instrumentation.');

    fig2 = uifigure('Visible', 'off', 'Name', 'labkit_debug_explicit_scroll_probe');
    cleaner2 = onCleanup(@() delete(fig2));
    scrollCalls = 0;
    fig2.WindowScrollWheelFcn = @onScroll;
    explicitDebug = labkit.ui.debug.context('probe_app', struct());
    scrollCount = explicitDebug.instrumentFigure(fig2, ...
        struct('callbackProperties', "WindowScrollWheelFcn"));
    assert(scrollCount == 1, ...
        'Explicit debug instrumentation should still be able to wrap scroll callbacks.');
    fig2.WindowScrollWheelFcn(fig2, []);
    scrollLines = string(explicitDebug.getLog());
    assert(scrollCalls == 1 && any(contains(scrollLines, 'WindowScrollWheelFcn')), ...
        'Explicit scroll instrumentation should trace and call the original scroll callback.');

    function onAction(varargin)
        buttonCalls = buttonCalls + 1;
    end

    function onCellAction(varargin)
        cellCallbackArg = string(varargin{end});
    end

    function onScroll(varargin)
        scrollCalls = scrollCalls + 1;
    end
end

function checkAttachedTextLogReceivesTraceLines(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_debug_text_log_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [1 1]);
    txt = uitextarea(grid, 'Value', {'Started.'}, 'Editable', 'off');

    debug = labkit.ui.debug.context('probe_app', struct());
    debug.attachTextLog(txt);
    debug.trace('loader', 'first trace', 'test');
    debug.trace('loader', 'second trace', 'test');

    lines = string(debug.getLog());
    values = string(txt.Value);
    assert(numel(lines) == 2, ...
        'Attached text logs should not change the in-memory debug log.');
    assert(numel(values) == 3, ...
        'Attached text logs should append exactly one UI row per trace line.');
    assert(contains(values(end - 1), 'component=loader') && ...
        contains(values(end - 1), 'event=first trace') && ...
        contains(values(end), 'event=second trace'), ...
        'Attached text logs should preserve trace order and message content.');
end

function checkDiagnosticReports()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeFolder(folder));
    logFile = fullfile(folder, 'probe.log');
    crashFile = fullfile(folder, 'probe_crash.txt');
    activeFile = fullfile(folder, 'probe_active.txt');
    debug = labkit.ui.debug.context('probe_app', struct( ...
        'logFile', logFile, ...
        'crashReportFile', crashFile, ...
        'activeOperationFile', activeFile, ...
        'stallTimeoutSeconds', 5));

    wrappedOk = debug.wrapCallback('normal callback', @normalCallback);
    wrappedOk();
    assert(exist(activeFile, 'file') ~= 2, ...
        'Completed callbacks should clear the active-operation report.');

    wrappedError = debug.wrapCallback('failing callback', @failingCallback);
    assertExpectedFailure(@() wrappedError());
    report = string(fileread(crashFile));
    assert(contains(report, 'status=error') && ...
        contains(report, 'operation=failing callback') && ...
        contains(report, 'error_id=probe:ExpectedFailure') && ...
        contains(report, 'recent_operations:') && ...
        contains(report, 'BEGIN failing callback') && ...
        contains(report, 'ERROR failing callback'), ...
        'Unhandled callback errors should write exact errors and recent operation repro steps.');

    try
        failingCallback();
    catch ME
        debug.reportException('loader', 'caught failure', ME);
    end
    report = string(fileread(crashFile));
    assert(contains(report, 'status=caught_error') && ...
        contains(report, 'operation=loader caught failure') && ...
        contains(report, 'error_id=probe:ExpectedFailure'), ...
        'Caught app exceptions should be reportable through the debug context.');

    modalCrashFile = fullfile(folder, 'modal_crash.txt');
    modalDebug = labkit.ui.debug.context('probe_app', struct( ...
        'logFile', fullfile(folder, 'modal.log'), ...
        'crashReportFile', modalCrashFile, ...
        'activeOperationFile', fullfile(folder, 'modal_active.txt'), ...
        'stallTimeoutSeconds', 0.1));
    wrappedModal = modalDebug.wrapCallback('modal file chooser callback', @modalFileChooserCallback);
    wrappedModal();
    assert(exist(modalCrashFile, 'file') ~= 2, ...
        'File chooser modal time should not be reported as a stalled app callback.');

    function normalCallback()
        assert(exist(activeFile, 'file') == 2, ...
            'Running callbacks should leave an active-operation report on disk.');
    end

    function failingCallback()
        error('probe:ExpectedFailure', 'Expected diagnostic failure.');
    end

    function modalFileChooserCallback()
        modalDebug.trace('filePanel', 'inputs file chooser start', 'mode=multi');
        pause(0.2);
        drawnow;
        modalDebug.trace('filePanel', 'inputs file chooser end', 'count=1');
    end
end

function checkFilePanelSemanticTrace()
    layout = labkit.ui.layout.workbench('filePanelTraceProbe', 'FilePanel Trace Probe', ...
        'controlTabs', {labkit.ui.layout.tab('setup', 'Setup', { ...
        labkit.ui.layout.section('inputSection', 'Inputs', { ...
        labkit.ui.layout.filePanel('inputs', 'Inputs', ...
        'dialogProvider', @(~) [string(fullfile(tempdir, 'a.png')); ...
        string(fullfile(tempdir, 'b.png'))], ...
        'onChoose', @noop)})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
        labkit.ui.layout.previewArea('preview', 'Preview')}));
    debug = labkit.ui.debug.context('probe_app', struct());
    ui = labkit.ui.runtime.create(layout, 'debug', debug);
    cleaner = onCleanup(@() delete(ui.figure));

    ui.controls.inputs.chooseButton.ButtonPushedFcn( ...
        ui.controls.inputs.chooseButton, struct());

    lines = string(debug.getLog());
    assert(any(contains(lines, 'component=filePanel') & ...
        contains(lines, 'event=inputs choose requested') & ...
        contains(lines, 'reason=user')), ...
        'filePanel should trace the start of a choose request.');
    assert(any(contains(lines, 'component=filePanel') & ...
        contains(lines, 'event=inputs paths selected') & ...
        contains(lines, 'reason=count=2')), ...
        'filePanel should trace the accepted path count before app callbacks run.');
    assert(any(contains(lines, 'component=filePanel') & ...
        contains(lines, 'event=inputs selection updated') & ...
        contains(lines, 'total=2 added=2')), ...
        'filePanel should trace framework selection updates.');
    assert(any(contains(lines, 'component=filePanel') & ...
        contains(lines, 'event=inputs callback start') & ...
        contains(lines, 'reason=action=choose')), ...
        'filePanel should trace before handing control to app code.');
    assert(any(contains(lines, 'component=filePanel') & ...
        contains(lines, 'event=inputs callback end') & ...
        contains(lines, 'reason=action=choose')), ...
        'filePanel should trace after app callbacks return.');
end

function noop(varargin)
end

function assertExpectedFailure(callback)
    failedAsExpected = false;
    try
        callback();
    catch ME
        failedAsExpected = strcmp(ME.identifier, 'probe:ExpectedFailure');
    end
    assert(failedAsExpected, ...
        'Diagnostic failure probe should throw the expected error id.');
end

function removeFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
