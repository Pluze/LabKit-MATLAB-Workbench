classdef GuiLayoutUiBusyStateTest < matlab.uitest.TestCase
    %GUILAYOUTUIBUSYSTATETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_busy_state(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_busy_state();
        end
    end
end

function verify_gui_layout_ui_busy_state()
%TEST_GUI_LAYOUT_UI_BUSY_STATE Verify runBusy app-wide busy contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = uifigure('Visible', 'off', 'Name', 'labkit_busy_state_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [4 1]);
    btnRun = uibutton(grid, 'Text', 'Run');
    btnExport = uibutton(grid, 'Text', 'Export', 'Enable', 'off');
    btnOther = uibutton(grid, 'Text', 'Other');
    ax = uiaxes(grid);
    oldHitTest = ax.HitTest;
    oldPickableParts = ax.PickableParts;
    fig.Pointer = 'arrow';
    scrollCallback = @scrollProbe;
    clickCallback = @clickProbe;
    fig.WindowScrollWheelFcn = scrollCallback;
    fig.WindowButtonDownFcn = clickCallback;

    result = labkit.ui.runtime.runBusy(fig, ...
        "Synthetic busy work", @probeWork);

    assert(result == 42, ...
        'Busy-state helper should return the work callback output.');
    assert(strcmp(btnRun.Enable, 'on'), ...
        'Busy-state helper should restore enabled controls.');
    assert(strcmp(btnExport.Enable, 'off'), ...
        'Busy-state helper should restore controls that started disabled.');
    assert(strcmp(btnOther.Enable, 'on'), ...
        'Busy-state helper should restore every app control.');
    assert(strcmp(fig.Pointer, 'arrow'), ...
        'Busy-state helper should restore the figure pointer.');
    assert(strcmp(fig.Name, 'labkit_busy_state_probe'), ...
        'Busy-state helper should restore the figure title.');
    assert(~isappdata(fig, 'labkitUiBusy'), ...
        'Busy-state helper should clear the busy flag after work.');
    assert(sameCallback(fig.WindowScrollWheelFcn, scrollCallback), ...
        'Busy-state helper should restore scroll callbacks.');
    assert(sameCallback(fig.WindowButtonDownFcn, clickCallback), ...
        'Busy-state helper should restore click callbacks.');
    assert(strcmp(char(ax.HitTest), char(oldHitTest)), ...
        'Busy-state helper should restore axes hit testing.');
    assert(strcmp(char(ax.PickableParts), char(oldPickableParts)), ...
        'Busy-state helper should restore axes pickable parts.');

    assertThrows(@() labkit.ui.runtime.runBusy(fig, ...
        "Failing busy work", @failingWork), ...
        'labkit:ui:test:BusyFailure', ...
        'Busy-state helper should rethrow callback errors.');
    assert(strcmp(btnRun.Enable, 'on') && strcmp(btnExport.Enable, 'off'), ...
        'Busy-state helper should restore control states after callback errors.');
    assert(strcmp(fig.Pointer, 'arrow'), ...
        'Busy-state helper should restore the pointer after callback errors.');
    assert(strcmp(fig.Name, 'labkit_busy_state_probe'), ...
        'Busy-state helper should restore the title after callback errors.');
    assert(~isappdata(fig, 'labkitUiBusy'), ...
        'Busy-state helper should clear the busy flag after callback errors.');

    fig.Name = 'labkit_busy_state_probe [Working: Previous]';
    nestedBusyTitle = "";
    labkit.ui.runtime.runBusy(fig, "Next step", @captureBusyTitle);
    assert(count(string(nestedBusyTitle), "[Working:") == 1, ...
        'Busy-state helper should not stack working labels.');
    assert(strcmp(fig.Name, 'labkit_busy_state_probe'), ...
        'Busy-state helper should restore the base title after nested labels.');

    verifyBusyActionWrapper();
    verifyBusyNonActionWrappers();
    verifyDebouncedParameterWrappers();
    verifyHiddenModeAlertRecording();
    verifyCloseGuard();
    verifyCloseKeyboardShortcut();

    function value = probeWork()
        assert(strcmp(btnRun.Enable, 'on'), ...
            'Busy-state helper should not mutate app-owned enabled controls.');
        assert(strcmp(btnExport.Enable, 'off'), ...
            'Busy-state helper should not mutate app-owned disabled controls.');
        assert(strcmp(btnOther.Enable, 'on'), ...
            'Busy-state helper should not mutate unrelated enabled controls.');
        assert(strcmp(fig.Pointer, 'watch'), ...
            'Busy-state helper should set a busy pointer during work.');
        assert(isappdata(fig, 'labkitUiBusy') && getappdata(fig, 'labkitUiBusy'), ...
            'Busy-state helper should mark the figure busy during work.');
        assert(contains(fig.Name, '[Working: Synthetic busy work]'), ...
            'Busy-state helper should expose busy text in the window title.');
        assert(isempty(fig.WindowScrollWheelFcn), ...
            'Busy-state helper should clear scroll callbacks during work.');
        assert(isempty(fig.WindowButtonDownFcn), ...
            'Busy-state helper should clear click callbacks during work.');
        assert(strcmp(char(ax.HitTest), 'off'), ...
            'Busy-state helper should turn axes hit testing off during work.');
        assert(strcmp(char(ax.PickableParts), 'none'), ...
            'Busy-state helper should turn axes pickable parts off during work.');
        value = 42;
    end

    function failingWork()
        assert(isappdata(fig, 'labkitUiBusy') && getappdata(fig, 'labkitUiBusy'), ...
            'Busy-state helper should mark the figure busy before failing work runs.');
        error('labkit:ui:test:BusyFailure', 'Synthetic busy-state failure.');
    end

    function captureBusyTitle()
        nestedBusyTitle = string(fig.Name);
    end

    function scrollProbe(~, ~)
    end

    function clickProbe(~, ~)
    end
end

function verifyHiddenModeAlertRecording()
    cleanupMode = setGuiTestModeForTest("hidden");
    debug = labkit.ui.debug.context('alert_probe_app', struct());
    layout = labkit.ui.layout.workbench('alertProbe', 'Alert Probe', ...
        'controlTabs', {labkit.ui.layout.tab('main', 'Main', { ...
        labkit.ui.layout.section('actions', 'Actions', { ...
        labkit.ui.layout.action('noop', 'Noop', @(~, ~) [])})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
        labkit.ui.layout.statusPanel('status', 'Status')}));
    ui = labkit.ui.runtime.create(layout, 'debug', debug);
    cleaner = onCleanup(@() deleteIfValid(ui.figure));

    shown = labkit.ui.runtime.showAlert(ui.figure, ...
        "Synthetic hidden alert message.", "Hidden Alert");

    assert(~shown, ...
        'showAlert should not open a modal dialog during hidden GUI tests.');
    assert(isappdata(ui.figure, 'labkitUiAlerts'), ...
        'showAlert should record hidden-mode alert payloads on the figure.');
    alerts = getappdata(ui.figure, 'labkitUiAlerts');
    assert(alerts(end).title == "Hidden Alert" && ...
        alerts(end).message == "Synthetic hidden alert message.", ...
        'showAlert should preserve app-owned alert title and message.');
    lines = string(debug.getLog());
    assert(any(contains(lines, 'component=alert') & ...
        contains(lines, 'reason=skipped-hidden-gui')), ...
        'showAlert should trace hidden-mode alert skips through the debug context.');
    clear cleanupMode;
end

function verifyCloseKeyboardShortcut()
    confirmCalls = 0;
    layout = labkit.ui.layout.workbench('closeShortcutProbe', 'Close Shortcut Probe', ...
        'controlTabs', {labkit.ui.layout.tab('main', 'Main', { ...
        labkit.ui.layout.section('actions', 'Actions', { ...
        labkit.ui.layout.action('noop', 'Noop', @(~, ~) [])})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
        labkit.ui.layout.statusPanel('status', 'Status')}));
    ui = labkit.ui.runtime.create(layout);
    cleaner = onCleanup(@() deleteIfValid(ui.figure));
    keyFcn = ui.figure.WindowKeyPressFcn;
    assert(isa(keyFcn, 'function_handle'), ...
        'LabKit runtime figures should install a close keyboard shortcut callback.');

    labkit.ui.runtime.setCloseGuard(ui.figure, true, "Shortcut probe work.");
    setappdata(ui.figure, 'labkitUiCloseConfirmFcn', @confirmCancel);
    keyFcn(ui.figure, struct('Key', 'w', 'Modifier', {{'command'}}));
    assert(isvalid(ui.figure), ...
        'Cmd+W should use close guard and keep the figure open when close is cancelled.');
    assert(confirmCalls == 1, ...
        'Cmd+W should call the close confirmation path.');

    setappdata(ui.figure, 'labkitUiCloseConfirmFcn', @confirmClose);
    keyFcn(ui.figure, struct('Key', 'w', 'Modifier', {{'control'}}));
    assert(~isvalid(ui.figure), ...
        'Ctrl+W should use the same close shortcut path and close when confirmed.');

    function response = confirmCancel(~, ~)
        confirmCalls = confirmCalls + 1;
        response = "Cancel";
    end

    function response = confirmClose(~, ~)
        confirmCalls = confirmCalls + 1;
        response = "Close";
    end
end

function verifyCloseGuard()
    confirmCalls = 0;
    lastMessage = "";
    layout = labkit.ui.layout.workbench('closeGuardProbe', 'Close Guard Probe', ...
        'controlTabs', {labkit.ui.layout.tab('main', 'Main', { ...
        labkit.ui.layout.section('actions', 'Actions', { ...
        labkit.ui.layout.action('noop', 'Noop', @(~, ~) [])})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
        labkit.ui.layout.statusPanel('status', 'Status')}));
    ui = labkit.ui.runtime.create(layout);
    cleaner = onCleanup(@() deleteIfValid(ui.figure));
    setappdata(ui.figure, 'labkitUiCloseConfirmFcn', @confirmCancel);
    closeFcn = ui.figure.CloseRequestFcn;

    labkit.ui.runtime.setCloseGuard(ui.figure, true, "Unfinished probe work.");
    closeFcn(ui.figure, struct());
    assert(isvalid(ui.figure), ...
        'Close guard should keep the figure open when the user cancels.');
    assert(confirmCalls == 1 && lastMessage == "Unfinished probe work.", ...
        'Close guard should use the app-provided dirty-state message.');

    setappdata(ui.figure, 'labkitUiBusy', true);
    setappdata(ui.figure, 'labkitUiCloseConfirmFcn', @confirmClose);
    closeFcn(ui.figure, struct());
    assert(~isvalid(ui.figure), ...
        'Close guard should close the figure when the user confirms.');
    assert(confirmCalls == 2 && contains(lastMessage, "still working"), ...
        'Close guard should prefer the framework busy message while busy.');

    function response = confirmCancel(~, message)
        confirmCalls = confirmCalls + 1;
        lastMessage = string(message);
        response = "Cancel";
    end

    function response = confirmClose(~, message)
        confirmCalls = confirmCalls + 1;
        lastMessage = string(message);
        response = "Close";
    end
end

function cleanup = setGuiTestModeForTest(mode)
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', char(mode));
    cleanup = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
end

function verifyBusyNonActionWrappers()
    pathCount = 0;
    tableCount = 0;
    duplicateCount = 0;
    layout = labkit.ui.layout.workbench('busyNonActionProbe', 'Busy Non-Action Probe', ...
        'controlTabs', {labkit.ui.layout.tab('main', 'Main', { ...
        labkit.ui.layout.section('inputs', 'Inputs', { ...
        labkit.ui.layout.filePanel('pathProbe', 'Inputs', ...
        'selectionMode', 'multiple', ...
        'dialogProvider', @(~) {'/tmp/a.txt', "/tmp/b.txt"}, ...
        'onChoose', @onPathChoose), ...
        labkit.ui.layout.action('otherProbe', 'Other probe', @onOtherProbe)})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
        labkit.ui.layout.resultTable('tableProbe', 'Table', ...
        'columns', {'A'}, ...
        'data', {1}, ...
        'onCellEdit', @onTableEdit)}));
    ui = labkit.ui.runtime.create(layout);
    cleaner = onCleanup(@() delete(ui.figure));

    chooseCallback = ui.controls.pathProbe.chooseButton.ButtonPushedFcn;
    chooseCallback(ui.controls.pathProbe.chooseButton, struct());
    assert(pathCount == 1, ...
        'filePanel callbacks should run once inside a busy transaction.');
    assert(duplicateCount == 0, ...
        'filePanel busy transaction should drop duplicate action callbacks.');
    assert(~isappdata(ui.figure, 'labkitUiBusy'), ...
        'filePanel busy transaction should clear busy state after completion.');

    tableCallback = ui.controls.tableProbe.table.CellEditCallback;
    tableCallback(ui.controls.tableProbe.table, struct('Indices', [1 1], ...
        'PreviousData', 1, 'NewData', 2, 'EditData', '2'));
    assert(tableCount == 1, ...
        'Table edit callbacks should run once inside a busy transaction.');
    assert(duplicateCount == 0, ...
        'Table edit busy transaction should drop duplicate action callbacks.');
    assert(~isappdata(ui.figure, 'labkitUiBusy'), ...
        'Table edit busy transaction should clear busy state after completion.');

    function onPathChoose(~, event)
        pathCount = pathCount + 1;
        addedFilePaths = labkit.ui.control.filePaths(event.addedFiles);
        allPaths = labkit.ui.control.filePaths(event.files);
        assert(isstring(addedFilePaths) && iscolumn(addedFilePaths) && ...
            numel(addedFilePaths) == 2 && isequal(addedFilePaths, allPaths), ...
            'filePanel event should expose selected files.');
        assert(isappdata(ui.figure, 'labkitUiBusy') && ...
            getappdata(ui.figure, 'labkitUiBusy'), ...
            'filePanel callback should run while the figure is marked busy.');
        otherCallback = ui.controls.otherProbe.button.ButtonPushedFcn;
        otherCallback(ui.controls.otherProbe.button, struct());
    end

    function onTableEdit(~, event)
        tableCount = tableCount + 1;
        assert(isequal(event.indices, [1 1]), ...
            'Table edit event should preserve edit indices.');
        assert(isappdata(ui.figure, 'labkitUiBusy') && ...
            getappdata(ui.figure, 'labkitUiBusy'), ...
            'Table callback should run while the figure is marked busy.');
        otherCallback = ui.controls.otherProbe.button.ButtonPushedFcn;
        otherCallback(ui.controls.otherProbe.button, struct());
    end

    function onOtherProbe(~, ~)
        duplicateCount = duplicateCount + 1;
    end
end

function verifyDebouncedParameterWrappers()
    h = guiTestHelpers();
    count = 0;
    values = [];
    layout = labkit.ui.layout.workbench('debouncedParameterProbe', ...
        'Debounced Parameter Probe', ...
        'controlTabs', {labkit.ui.layout.tab('main', 'Main', { ...
        labkit.ui.layout.section('params', 'Params', { ...
        labkit.ui.layout.field('gain', 'Gain', ...
        'kind', 'number', ...
        'value', 1, ...
        'onChange', @onGainChanged)})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', {}));
    ui = labkit.ui.runtime.create(layout);
    cleaner = onCleanup(@() delete(ui.figure));

    ui.controls.gain.handle.Value = 2;
    ui.controls.gain.handle.ValueChangedFcn(ui.controls.gain.handle, struct());
    ui.controls.gain.handle.Value = 3;
    ui.controls.gain.handle.ValueChangedFcn(ui.controls.gain.handle, struct());
    ui.controls.gain.handle.Value = 4;
    ui.controls.gain.handle.ValueChangedFcn(ui.controls.gain.handle, struct());
    h.waitForUiIdle(ui.figure);

    assert(count == 1 && isequal(values, 4), ...
        'Parameter callbacks should debounce rapid value changes and submit only the latest value.');

    function onGainChanged(~, event)
        count = count + 1;
        values(end + 1) = event.value;
    end
end

function verifyBusyActionWrapper()
    count = 0;
    duplicateCount = 0;
    layout = labkit.ui.layout.workbench('busyActionProbe', 'Busy Action Probe', ...
        'controlTabs', {labkit.ui.layout.tab('main', 'Main', { ...
        labkit.ui.layout.section('actions', 'Actions', { ...
        labkit.ui.layout.action('runProbe', 'Run probe', @onRunProbe), ...
        labkit.ui.layout.action('otherProbe', 'Other probe', @onOtherProbe)})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
        labkit.ui.layout.statusPanel('status', 'Status')}));
    ui = labkit.ui.runtime.create(layout);
    cleaner = onCleanup(@() delete(ui.figure));
    ui.figure.Pointer = 'arrow';
    ui.figure.WindowButtonDownFcn = @beforeActionClick;

    button = ui.controls.runProbe.button;
    callback = button.ButtonPushedFcn;
    callback(button, struct());
    assert(count == 1, ...
        'Action transaction should run the app callback once.');
    assert(strcmp(ui.figure.Pointer, 'crosshair'), ...
        'Action transaction should not roll back app-owned pointer changes.');
    assert(sameCallback(ui.figure.WindowButtonDownFcn, @afterActionClick), ...
        'Action transaction should not roll back app-owned figure callbacks.');
    callback(button, struct());
    assert(count == 2, ...
        'Action transaction should clear busy state after completion.');
    assert(duplicateCount == 0, ...
        'Action transaction should drop other actions while the figure is busy.');

    function onRunProbe(~, ~)
        count = count + 1;
        otherCallback = ui.controls.otherProbe.button.ButtonPushedFcn;
        otherCallback(ui.controls.otherProbe.button, struct());
        ui.figure.Pointer = 'crosshair';
        ui.figure.WindowButtonDownFcn = @afterActionClick;
        assert(strcmp(button.Enable, 'on'), ...
            'Action busy wrapper should not mutate app-owned Enable state.');
        assert(isappdata(ui.figure, 'labkitUiBusy') && ...
            getappdata(ui.figure, 'labkitUiBusy'), ...
            'Action busy wrapper should mark the figure busy during work.');
        assert(contains(ui.figure.Name, '[Working: Run probe]'), ...
            'Action busy wrapper should expose the action label in the figure title.');
    end

    function onOtherProbe(~, ~)
        duplicateCount = duplicateCount + 1;
    end

    function beforeActionClick(~, ~)
    end

    function afterActionClick(~, ~)
    end
end

function assertThrows(fn, expectedIdentifier, label)
    try
        fn();
    catch ME
        assert(strcmp(ME.identifier, expectedIdentifier), ...
            '%s Expected %s but caught %s.', ...
            label, expectedIdentifier, ME.identifier);
        return;
    end
    error('%s Expected an error with identifier %s.', label, expectedIdentifier);
end

function tf = sameCallback(actual, expected)
    tf = isa(actual, 'function_handle') && ...
        isa(expected, 'function_handle') && ...
        strcmp(func2str(actual), func2str(expected));
end

function deleteIfValid(fig)
    if ~isempty(fig) && isvalid(fig)
        delete(fig);
    end
end
