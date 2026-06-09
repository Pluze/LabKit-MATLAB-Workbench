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
%TEST_GUI_LAYOUT_UI_BUSY_STATE Verify runWithBusyState contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = uifigure('Visible', 'off', 'Name', 'labkit_busy_state_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [3 1]);
    btnRun = uibutton(grid, 'Text', 'Run');
    btnExport = uibutton(grid, 'Text', 'Export', 'Enable', 'off');
    btnOther = uibutton(grid, 'Text', 'Other');
    fig.Pointer = 'arrow';

    opts = struct();
    opts.showDialog = false;
    opts.controls = {btnRun, btnExport};
    result = labkit.ui.app.runBusy(fig, @probeWork, opts);

    assert(result == 42, ...
        'Busy-state helper should return the work callback output.');
    assert(strcmp(btnRun.Enable, 'on'), ...
        'Busy-state helper should restore enabled controls.');
    assert(strcmp(btnExport.Enable, 'off'), ...
        'Busy-state helper should restore controls that started disabled.');
    assert(strcmp(btnOther.Enable, 'on'), ...
        'Busy-state helper should not touch controls outside opts.controls.');
    assert(strcmp(fig.Pointer, 'arrow'), ...
        'Busy-state helper should restore the figure pointer.');

    assertThrows(@() labkit.ui.app.runBusy(fig, @failingWork, opts), ...
        'labkit:ui:test:BusyFailure', ...
        'Busy-state helper should rethrow callback errors.');
    assert(strcmp(btnRun.Enable, 'on') && strcmp(btnExport.Enable, 'off'), ...
        'Busy-state helper should restore control states after callback errors.');
    assert(strcmp(fig.Pointer, 'arrow'), ...
        'Busy-state helper should restore the pointer after callback errors.');

    function value = probeWork()
        assert(strcmp(btnRun.Enable, 'off'), ...
            'Busy-state helper should disable active controls during work.');
        assert(strcmp(btnExport.Enable, 'off'), ...
            'Busy-state helper should keep initially disabled controls off during work.');
        assert(strcmp(btnOther.Enable, 'on'), ...
            'Busy-state helper should leave unrelated controls enabled during work.');
        assert(strcmp(fig.Pointer, 'watch'), ...
            'Busy-state helper should set a busy pointer during work.');
        value = 42;
    end

    function failingWork()
        assert(strcmp(btnRun.Enable, 'off'), ...
            'Busy-state helper should disable controls before failing work runs.');
        error('labkit:ui:test:BusyFailure', 'Synthetic busy-state failure.');
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
