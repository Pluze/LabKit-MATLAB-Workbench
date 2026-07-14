classdef GuiStartupLifecycleTest < matlab.unittest.TestCase
    %GUISTARTUPLIFECYCLETEST Verify deferred GUI startup failures are rejected.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function startup_assertion_reports_deferred_failure(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanupFigures = onCleanup(@() h.closeAllFigures());
            fig = uifigure('Visible', 'off');
            startupState = struct( ...
                'failed', true, ...
                'message', "Startup failed: synthetic startup failure");
            setappdata(fig, 'labkitUiStartup', startupState);

            testCase.verifyError(@() h.assertStartupSucceeded(fig), ...
                'LabKit:Tests:GuiStartupFailed');
            clear cleanupFigures
            h.closeAllFigures();
        end
    end
end
