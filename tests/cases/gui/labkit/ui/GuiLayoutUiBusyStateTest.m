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

    result = labkit.ui.app.runBusy(fig, ...
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

    assertThrows(@() labkit.ui.app.runBusy(fig, ...
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
    labkit.ui.app.runBusy(fig, "Next step", @captureBusyTitle);
    assert(count(string(nestedBusyTitle), "[Working:") == 1, ...
        'Busy-state helper should not stack working labels.');
    assert(strcmp(fig.Name, 'labkit_busy_state_probe'), ...
        'Busy-state helper should restore the base title after nested labels.');

    verifyBusyActionWrapper();
    verifyBusyNonActionWrappers();

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

function verifyBusyNonActionWrappers()
    pathCount = 0;
    tableCount = 0;
    duplicateCount = 0;
    spec = labkit.ui.spec.app('busyNonActionProbe', 'Busy Non-Action Probe', ...
        'controlTabs', {labkit.ui.spec.tab('main', 'Main', { ...
        labkit.ui.spec.section('inputs', 'Inputs', { ...
        labkit.ui.spec.pathPanel('pathProbe', 'Inputs', ...
        'mode', 'multiFile', ...
        'dialogProvider', @(~) {'/tmp/a.txt', "/tmp/b.txt"}, ...
        'onChoose', @onPathChoose), ...
        labkit.ui.spec.action('otherProbe', 'Other probe', @onOtherProbe)})})}, ...
        'workspace', labkit.ui.spec.workspace('workspace', 'Preview', { ...
        labkit.ui.spec.resultTable('tableProbe', 'Table', ...
        'columns', {'A'}, ...
        'data', {1}, ...
        'onCellEdit', @onTableEdit)}));
    ui = labkit.ui.app.create(spec);
    cleaner = onCleanup(@() delete(ui.figure));

    chooseCallback = ui.controls.pathProbe.chooseButton.ButtonPushedFcn;
    chooseCallback(ui.controls.pathProbe.chooseButton, struct());
    assert(pathCount == 1, ...
        'Path-panel callbacks should run once inside a busy transaction.');
    assert(duplicateCount == 0, ...
        'Path-panel busy transaction should drop duplicate action callbacks.');
    assert(~isappdata(ui.figure, 'labkitUiBusy'), ...
        'Path-panel busy transaction should clear busy state after completion.');

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
        assert(isstring(event.paths) && iscolumn(event.paths) && ...
            numel(event.paths) == 2, ...
            'Path-panel event should expose selected paths as a string column.');
        assert(isappdata(ui.figure, 'labkitUiBusy') && ...
            getappdata(ui.figure, 'labkitUiBusy'), ...
            'Path-panel callback should run while the figure is marked busy.');
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

function verifyBusyActionWrapper()
    count = 0;
    duplicateCount = 0;
    spec = labkit.ui.spec.app('busyActionProbe', 'Busy Action Probe', ...
        'controlTabs', {labkit.ui.spec.tab('main', 'Main', { ...
        labkit.ui.spec.section('actions', 'Actions', { ...
        labkit.ui.spec.action('runProbe', 'Run probe', @onRunProbe), ...
        labkit.ui.spec.action('otherProbe', 'Other probe', @onOtherProbe)})})}, ...
        'workspace', labkit.ui.spec.workspace('workspace', 'Preview', { ...
        labkit.ui.spec.statusPanel('status', 'Status')}));
    ui = labkit.ui.app.create(spec);
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
