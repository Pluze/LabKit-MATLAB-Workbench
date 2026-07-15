classdef GuiStartupLifecycleTest < matlab.unittest.TestCase
    %GUISTARTUPLIFECYCLETEST Verify deferred GUI startup failures are rejected.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function completed_startup_releases_busy_state_and_hides_status(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanupFigures = onCleanup(@() h.closeAllFigures());
            layout = labkit.ui.layout.workbench('startupProbe', ...
                'Startup Probe', ...
                'controlTabs', {labkit.ui.layout.tab('setup', 'Setup', { ...
                    labkit.ui.layout.section('actions', 'Actions', { ...
                        labkit.ui.layout.action('run', 'Run', @noop)})})}, ...
                'workspace', labkit.ui.layout.workspace('workspace', ...
                    'Preview', {labkit.ui.layout.previewArea('preview', ...
                    'Preview')}));

            ui = labkit.ui.runtime.create(layout);

            testCase.verifyFalse(isappdata(ui.figure, 'labkitUiStartup'), ...
                'Completed startup should remove transient lifecycle state.');
            testCase.verifyFalse(isappdata(ui.figure, 'labkitUiBusy'), ...
                'Completed startup should release callback busy gating.');
            testCase.verifyEqual(string(ui.startupStatusPanel.Visible), "off", ...
                'Completed startup should hide the readiness surface.');
            testCase.verifyEqual(ui.main.RowHeight{2}, 0, ...
                'Completed startup should collapse the readiness row.');
            clear cleanupFigures
            h.closeAllFigures();
        end

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

function noop(varargin)
end
