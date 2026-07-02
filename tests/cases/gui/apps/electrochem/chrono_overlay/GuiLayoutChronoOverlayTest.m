classdef GuiLayoutChronoOverlayTest < matlab.uitest.TestCase
    %GUILAYOUTCHRONOOVERLAYTEST Verify chrono overlay GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function chrono_overlay_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_ChronoOverlay_app', ...
                'Gamry Multi-DTA Plot Export GUI');
            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
                'Clear all', 'Export curves CSV'});
            h.assertCheckboxContract(fig, {'Show file-name legend', 'Show grid'});
            h.assertDropdownGroups(fig, h.dropdownGroup( ...
                {'Time (s)', 'Time (ms)', 'Sample #'}, 1));
            h.assertTabTitles(fig, {'Files + Analysis', 'Log'});
            h.assertDropdownCallbacksPresent(fig);
            h.invokeDropdownValue(fig, 'Time (ms)');
            h.invokeCheckbox(fig, 'Show file-name legend', false);
        end
    end

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function chrono_overlay_debug_launch_generates_boundary_samples(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            [fig, debug] = labkit_ChronoOverlay_app("debug");
            testCase.verifyTrue(debug.enabled && debug.traceEnabled, ...
                'Chrono overlay debug launch should return an enabled trace logger.');
            testCase.verifyTrue(isfolder(debug.sampleFolder), ...
                'Chrono overlay debug launch should create a controlled samples folder.');
            testCase.verifyTrue(isfolder(debug.outputFolder), ...
                'Chrono overlay debug launch should create a controlled output folder.');
            testCase.verifyTrue(isfile(debug.manifestFile), ...
                'Chrono overlay debug launch should record a sample manifest.');

            driver = labkitWorkflowDriver(fig);
            testCase.verifyEqual(char(driver.fileStatus('files')), 'No files loaded');

            manifestText = string(fileread(debug.manifestFile));
            testCase.verifyTrue(contains(manifestText, 'malformedChronoDta') && ...
                contains(manifestText, 'validEdgeChronoDta'), ...
                'Chrono overlay debug manifest should include boundary-test samples.');
        end

        function chrono_overlay_workflow_loads_and_plots_chrono_files(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixtures = [ ...
                string(dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA')); ...
                string(dtaFixturePath('chrono_chronoamp_voltage_pulse_0p2ms.DTA'))];
            fig = h.launchFigure('labkit_ChronoOverlay_app', ...
                'Gamry Multi-DTA Plot Export GUI');
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('files', fixtures);

            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '2 file(s) loaded');
            testCase.verifyEqual(numel(driver.fileListItems('files')), 2, ...
                'Chrono overlay workflow should list both loaded chrono fixtures.');
            ui = driver.registry();
            axVoltage = ui.controls.overlayPlots.axesById.voltage;
            axCurrent = ui.controls.overlayPlots.axesById.current;
            testCase.verifyGreaterThan(numel(axVoltage.Children), 0, ...
                'Chrono overlay workflow should draw voltage traces.');
            testCase.verifyGreaterThan(numel(axCurrent.Children), 0, ...
                'Chrono overlay workflow should draw current traces.');

            driver.dropdown('Time (ms)');
            testCase.verifyTrue(contains(string(axVoltage.XLabel.String), "Time (ms)"));
            testCase.verifyTrue(contains(string(axCurrent.XLabel.String), "Time (ms)"));
        end
    end
end
