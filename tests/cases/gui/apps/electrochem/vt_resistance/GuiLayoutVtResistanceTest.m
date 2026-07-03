classdef GuiLayoutVtResistanceTest < matlab.uitest.TestCase
    %GUILAYOUTVTRESISTANCETEST Verify VT resistance GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function vt_resistance_workflow_loads_analyzes_and_plots_chrono(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
            secondFixture = dtaFixturePath('chrono_chronopot_current_pulse_1ms.DTA');
            fig = h.launchFigure('labkit_VTResistance_app', ...
                'Gamry VT Steady Resistance GUI');
            assertVtResistanceLayout(h, fig);
            verifyVtPlotAxisClearRemovesAnnotations();
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('files', fixture);

            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '1 file(s) loaded');
            testCase.verifyTrue(any(contains(driver.fileListItems('files'), ...
                'chrono_chronopot_current_pulse_0p2ms.DTA')), ...
                'VT resistance workflow should list the loaded chrono fixture.');
            data = driver.tableData('results');
            testCase.verifyEqual(size(data), [1 9], ...
                'VT resistance workflow should populate one batch result row.');
            testCase.verifyEqual(string(data{1, 9}), "metadata-current", ...
                'VT resistance workflow should report metadata-backed pulse detection.');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.status.valueHandle.Value), 'OK'), ...
                'VT resistance workflow should refresh the current-file status field.');
            testCase.verifyTrue(contains(string(ui.controls.averageR.valueHandle.Value), 'ohm'), ...
                'VT resistance workflow should refresh computed resistance summary fields.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.top.Children), 0, ...
                'VT resistance workflow should draw the top plot.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.bottom.Children), 0, ...
                'VT resistance workflow should draw the bottom plot.');

            driver.chooseFiles('files', secondFixture);
            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '2 file(s) loaded');
            testCase.verifyTrue(contains(driver.fileSelection('files'), ...
                'chrono_chronopot_current_pulse_1ms.DTA'), ...
                'VT resistance append should select the newly added chrono file.');
        end
    end
end

function assertVtResistanceLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
        'Clear all', 'Export results CSV'});
    h.assertTextsAbsent(fig, {'Re-analyze file', 'Refresh plots', ...
        'Swap top / bottom', 'Reset axes'});
    h.assertCheckboxContract(fig, {'Show markers', 'Shade windows', 'Grid'});
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Metadata first, then auto', 'Metadata only', ...
        'Auto from Im only'}, 1), ...
        h.dropdownGroup({'Full pulse median', 'Center 60% median'}, 1), ...
        h.dropdownGroup({'Baseline-corrected dV/I', 'Raw Vf/I'}, 1), ...
        h.dropdownGroup({'Time (s)', 'Sample #'}, 2), ...
        h.dropdownGroup({'VT: Vf vs time', 'IT: Im vs time'}, 2)]);
    h.assertDropdownCallbacksPresent(fig);
end

function verifyVtPlotAxisClearRemovesAnnotations()
    fig = uifigure('Visible', 'off');
    cleaner = onCleanup(@() delete(fig));
    ax = uiaxes(fig);
    plot(ax, 1:3, [1 4 2], 'HandleVisibility', 'off');
    hold(ax, 'on');
    xline(ax, 2, ':', 'marker');
    text(ax, 2, 3, 'annotation', 'HandleVisibility', 'off');
    vt_resistance.userInterface.clearPlotAxis(ax);
    assert(isempty(ax.Children), ...
        'VT plot refresh should remove previous hidden markers and annotations.');
    assert(strcmp(ax.XLimMode, 'auto') && strcmp(ax.YLimMode, 'auto'), ...
        'VT plot refresh should restore automatic axis limits.');
end
