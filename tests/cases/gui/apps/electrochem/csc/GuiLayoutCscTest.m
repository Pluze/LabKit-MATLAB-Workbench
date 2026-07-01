classdef GuiLayoutCscTest < matlab.uitest.TestCase
    %GUILAYOUTCSCTEST Verify CSC GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function csc_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_CSC_app', 'Gamry DTA GUI (literature CSC)');
            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
                'Clear all', 'Reload selected', ...
                'Auto CV + CT', 'Swap Top/Bottom', 'Compare Q / CSC', ...
                'Refresh Plots', 'Clear Both'});
            h.assertCheckboxContract(fig, {'Grid', 'Hold', 'Show Trim'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'(none)'}, 5), ...
                h.dropdownGroup({'Full', 'Cathodic', 'Anodic'}, 1)]);
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertDropdownCallbacksPresent(fig);
            h.invokeDropdownValue(fig, 'Cathodic');
        end
    end

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function csc_workflow_loads_cvct_compares_and_plots(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');
            fig = h.launchFigure('labkit_CSC_app', ...
                'Gamry DTA GUI (literature CSC)');
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('files', fixture);

            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '1 file(s) loaded');
            testCase.verifyTrue(any(contains(driver.fileListItems('files'), ...
                'cv_cyclic_voltammetry_pt_reference.DTA')), ...
                'CSC workflow should list the loaded CV/CT fixture.');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.scanRate.valueHandle.Value), ...
                'V/s'), ...
                'CSC workflow should refresh the scan-rate field.');
            testCase.verifyGreaterThan(numel(ui.controls.curve.valueHandle.Items), 1, ...
                'CSC workflow should populate parsed curve choices.');
            testCase.verifyTrue(contains(string(ui.controls.qct.valueHandle.Value), 'C'), ...
                'CSC workflow should refresh CT charge readout.');
            testCase.verifyTrue(contains(string(ui.controls.qcv.valueHandle.Value), 'C'), ...
                'CSC workflow should refresh CV charge readout.');
            testCase.verifyTrue(strlength(string(ui.controls.status.valueHandle.Value)) > 1, ...
                'CSC workflow should refresh comparison status.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.top.Children), 0, ...
                'CSC workflow should draw the top plot.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.bottom.Children), 0, ...
                'CSC workflow should draw the bottom plot.');
        end
    end
end
