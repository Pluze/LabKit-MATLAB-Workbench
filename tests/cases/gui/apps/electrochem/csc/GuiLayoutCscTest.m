classdef GuiLayoutCscTest < matlab.unittest.TestCase
    %GUILAYOUTCSCTEST Verify CSC GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function csc_workflow_loads_cvct_compares_and_plots(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('cv_cyclic_voltammetry_pt_reference.DTA');
            secondFixture = dtaFixturePath('cv_cyclic_voltammetry_pt_replicate.DTA');
            fig = h.launchFigure('labkit_CSC_app', ...
                'Gamry DTA GUI (literature CSC)');
            assertCscLayout(h, fig);
            h.invokeDropdownValue(fig, 'Cathodic');
            h.invokeDropdownValue(fig, 'Full');
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
            testCase.verifyEqual(string(ui.controls.curve.valueHandle.Value), "All cycles", ...
                'CSC workflow should default to all-cycle display.');
            cycleData = driver.tableData('cycleResults');
            testCase.verifyEqual(size(cycleData, 1), ...
                numel(ui.controls.curve.valueHandle.Items) - 1, ...
                'CSC workflow should show one CSC row per parsed cycle.');
            driver.checkbox('Ignore first/last cycle', true);
            cycleData = driver.tableData('cycleResults');
            testCase.verifyEqual(size(cycleData, 1), ...
                max(0, numel(ui.controls.curve.valueHandle.Items) - 3), ...
                'CSC workflow should optionally ignore first and last cycle results.');
            driver.checkbox('Ignore first/last cycle', false);
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.top.Children), 1, ...
                'CSC all-cycle workflow should draw multiple colored cycle lines.');
            topAxes = ui.controls.plotAxes.axesById.top;
            staleXLim = [-0.01 0.01];
            topAxes.XLim = staleXLim;
            ui.controls.topX.valueHandle.Value = 'Vf';
            h.invokeCallback(ui.controls.topX.valueHandle, 'ValueChangedFcn');
            h.waitForUiIdle(fig);
            testCase.verifyNotEqual(topAxes.XLim, staleXLim, ...
                'CSC plot selection changes should reset stale X limits.');
            h.invokeDropdownValue(fig, ui.controls.curve.valueHandle.Items{2});
            singleStaleYLim = [-1e-12 1e-12];
            topAxes.YLim = singleStaleYLim;
            ui.controls.topY.valueHandle.Value = 'Im';
            h.invokeCallback(ui.controls.topY.valueHandle, 'ValueChangedFcn');
            h.waitForUiIdle(fig);
            testCase.verifyNotEqual(topAxes.YLim, singleStaleYLim, ...
                'CSC single-cycle plot refresh should reset stale Y limits.');
            testCase.verifyTrue(contains(string(ui.controls.qct.valueHandle.Value), 'C'), ...
                'CSC single-cycle workflow should refresh CT charge readout.');
            testCase.verifyTrue(contains(string(ui.controls.qcv.valueHandle.Value), 'C'), ...
                'CSC single-cycle workflow should refresh CV charge readout.');
            testCase.verifyTrue(strlength(string(ui.controls.status.valueHandle.Value)) > 1, ...
                'CSC workflow should refresh comparison status.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.bottom.Children), 0, ...
                'CSC workflow should draw the bottom plot.');

            driver.chooseFiles('files', secondFixture);
            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '2 file(s) loaded');
            testCase.verifyTrue(contains(driver.fileSelection('files'), ...
                'cv_cyclic_voltammetry_pt_replicate.DTA'), ...
                'CSC append should select the newly added CV/CT file.');

            topAxes.XLim = [-0.01 0.01];
            topAxes.YLim = [-1e-12 1e-12];
            driver.click('Clear all');
            testCase.verifyEqual(char(driver.fileStatus('files')), 'No files loaded');
            testCase.verifyEmpty(topAxes.Children, ...
                'CSC clear-all should remove stale top plot graphics.');
            testCase.verifyEmpty(ui.controls.plotAxes.axesById.bottom.Children, ...
                'CSC clear-all should remove stale bottom plot graphics.');
            testCase.verifyEqual(topAxes.XLimMode, 'auto', ...
                'CSC clear-all should restore automatic X limits.');
            testCase.verifyEqual(topAxes.YLimMode, 'auto', ...
                'CSC clear-all should restore automatic Y limits.');
        end
    end
end

function assertCscLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
        'Clear all', 'Reload selected', 'Export all cycles CSV', ...
        'Export CV data CSV'});
    h.assertTextsAbsent(fig, {'Auto CV + CT', 'Swap Top/Bottom', ...
        'Compare Q / CSC', 'Refresh Plots', 'Clear Both'});
    h.assertCheckboxContract(fig, {'Grid', 'Hold', 'Show Trim'});
    h.assertCheckboxContract(fig, {'Ignore first/last cycle'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'(none)'}, 5), ...
        h.dropdownGroup({'Full', 'Cathodic', 'Anodic'}, 1)]);
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertDropdownCallbacksPresent(fig);
end
