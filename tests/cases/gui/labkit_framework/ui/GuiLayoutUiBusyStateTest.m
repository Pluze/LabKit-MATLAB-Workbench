classdef GuiLayoutUiBusyStateTest < matlab.unittest.TestCase
    %GUILAYOUTUIBUSYSTATETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_busy_state(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_busy_state();
        end
    end
end

function verify_gui_layout_ui_busy_state()
%TEST_GUI_LAYOUT_UI_BUSY_STATE Verify app-wide semantic busy transactions.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    verifyBusyActionWrapper();
    verifyBusyNonActionWrappers();
    verifyDebouncedParameterWrappers();
    verifyDefaultCloseGuard();
    verifyBusyCloseGuard();
    verifyCloseKeyboardShortcut();
    verifyDefaultClosePromptShortcut();

end

function verifyDefaultCloseGuard()
    confirmCalls = 0;
    lastMessage = "";
    layout = labkit.ui.layout.workbench('defaultCloseGuardProbe', ...
        'Default Close Guard Probe', ...
        'controlTabs', {labkit.ui.layout.tab('main', 'Main', { ...
        labkit.ui.layout.section('actions', 'Actions', { ...
        labkit.ui.layout.action('noop', 'Noop', @(~, ~) [])})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
        labkit.ui.layout.statusPanel('status', 'Status')}));
    ui = labkit.ui.runtime.create(layout);
    cleaner = onCleanup(@() deleteIfValid(ui.figure));
    setappdata(ui.figure, 'labkitUiCloseConfirmFcn', @confirmCancel);
    closeFcn = ui.figure.CloseRequestFcn;

    closeFcn(ui.figure, struct());
    assert(isvalid(ui.figure), ...
        'LabKit runtime figures should keep the figure open when default close confirmation is cancelled.');
    assert(confirmCalls == 1 && lastMessage == "Close this LabKit app?", ...
        'Default close guard should confirm even when the app has not marked dirty state.');

    setappdata(ui.figure, 'labkitUiCloseConfirmFcn', @confirmClose);
    closeFcn(ui.figure, struct());
    assert(~isvalid(ui.figure), ...
        'Default close guard should close the figure when the user confirms.');

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

function verifyDefaultClosePromptShortcut()
    layout = labkit.ui.layout.workbench('defaultClosePromptShortcutProbe', ...
        'Default Close Prompt Shortcut Probe', ...
        'controlTabs', {labkit.ui.layout.tab('main', 'Main', { ...
        labkit.ui.layout.section('actions', 'Actions', { ...
        labkit.ui.layout.action('noop', 'Noop', @(~, ~) [])})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
        labkit.ui.layout.statusPanel('status', 'Status')}));
    ui = labkit.ui.runtime.create(layout);
    cleaner = onCleanup(@() deleteIfValid(ui.figure));
    keyFcn = ui.figure.WindowKeyPressFcn;

    keyFcn(ui.figure, struct('Key', 'w', 'Modifier', {{'command'}}));
    prompt = findall(ui.figure, 'Tag', 'labkitUiClosePrompt');
    assert(isvalid(ui.figure) && ~isempty(prompt), ...
        'First Cmd+W should show an in-window close prompt and keep the figure open.');

    keyFcn(ui.figure, struct('Key', 'w', 'Modifier', {{'command'}}));
    assert(~isvalid(ui.figure), ...
        'Default close prompt should treat repeated Cmd+W as close confirmation.');
    drawnow;
    prompt = findall(groot, 'Tag', 'labkitUiClosePrompt');
    assert(isempty(prompt), ...
        'Default close prompt should be deleted after shortcut-confirmed close.');
end

function verifyBusyCloseGuard()
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

    setappdata(ui.figure, 'labkitUiBusy', true);
    closeFcn(ui.figure, struct());
    assert(isvalid(ui.figure), ...
        'Busy close guard should keep the figure open when the user cancels.');
    assert(confirmCalls == 1 && contains(lastMessage, "still working"), ...
        'Close guard should prefer the framework busy message while busy.');

    setappdata(ui.figure, 'labkitUiCloseConfirmFcn', @confirmClose);
    closeFcn(ui.figure, struct());
    assert(~isvalid(ui.figure), ...
        'Close guard should close the figure when the user confirms.');
    assert(confirmCalls == 2, ...
        'Busy close guard should call the confirmation path again before closing.');

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
    h = guiTestHelpers();
    pathCount = 0;
    tableCount = 0;
    selectionCount = 0;
    selectedIndices = zeros(0, 2);
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
                'data', {1; 2; 3}, ...
                'onCellEdit', @onTableEdit, ...
                'onSelectionChange', @onTableSelection)}));
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

    if isprop(ui.controls.tableProbe.table, 'SelectionChangedFcn')
        selectionCallback = ui.controls.tableProbe.table.SelectionChangedFcn;
        selectionField = 'Selection';
    else
        selectionCallback = ui.controls.tableProbe.table.CellSelectionCallback;
        selectionField = 'Indices';
    end
    selectionCallback(ui.controls.tableProbe.table, ...
        struct(selectionField, [1 1]));
    selectionCallback(ui.controls.tableProbe.table, ...
        struct(selectionField, [1 1; 2 1]));
    selectionCallback(ui.controls.tableProbe.table, ...
        struct(selectionField, [1 1; 2 1; 3 1]));
    assert(selectionCount == 0, ...
        'Rapid table selection changes should not commit synchronously.');
    h.waitForUiIdle(ui.figure);
    assert(selectionCount == 1 && ...
        isequal(selectedIndices, [1 1; 2 1; 3 1]), ...
        'Table selection should commit only the final coalesced range.');

    function onPathChoose(~, event)
        pathCount = pathCount + 1;
        addedFilePaths = testui.control.filePaths(event.addedFiles);
        allPaths = testui.control.filePaths(event.files);
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

    function onTableSelection(~, event)
        selectionCount = selectionCount + 1;
        selectedIndices = event.indices;
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
    if iscell(actual) && iscell(expected) && numel(actual) == numel(expected)
        tf = sameCallback(actual{1}, expected{1});
        for k = 2:numel(actual)
            tf = tf && sameCallbackArgument(actual{k}, expected{k});
        end
        return;
    end
    tf = isa(actual, 'function_handle') && ...
        isa(expected, 'function_handle') && ...
        strcmp(func2str(actual), func2str(expected));
end

function tf = sameCallbackArgument(actual, expected)
    tf = isequaln(actual, expected);
    if ~tf && (ischar(actual) || isstring(actual)) && ...
            (ischar(expected) || isstring(expected))
        tf = isequal(string(actual), string(expected));
    end
end

function deleteIfValid(fig)
    if ~isempty(fig) && isvalid(fig)
        delete(fig);
    end
end
