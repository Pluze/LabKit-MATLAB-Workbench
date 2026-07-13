classdef GuiLayoutCicTest < matlab.unittest.TestCase
    %GUILAYOUTCICTEST Verify CIC GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function cic_workflow_loads_analyzes_and_plots_chrono(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
            secondFixture = dtaFixturePath('chrono_chronopot_current_pulse_1ms.DTA');
            fig = h.launchFigure('labkit_CIC_app', ...
                'Gamry CIC GUI (Voltage Transient)');
            assertCicLayout(h, fig);
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('files', fixture);

            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '1 file(s) loaded');
            testCase.verifyTrue(any(contains(driver.fileListItems('files'), ...
                'chrono_chronopot_current_pulse_0p2ms.DTA')), ...
                'CIC workflow should list the loaded chrono fixture.');
            data = driver.tableData('results');
            testCase.verifyEqual(size(data), [1 8], ...
                'CIC workflow should populate one batch result row.');
            testCase.verifyTrue(isnumeric(data{1, 5}) && isfinite(data{1, 5}), ...
                'CIC workflow should compute a cathodic charge value.');
            testCase.verifyTrue(ischar(data{1, 8}) || isstring(data{1, 8}), ...
                'CIC workflow should populate the safety result column.');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.detect.valueHandle.Value), ...
                'metadata-current'), ...
                'CIC workflow should refresh the detection summary field.');
            testCase.verifyTrue(contains(string(ui.controls.qt.valueHandle.Value), 'C'), ...
                'CIC workflow should refresh computed total charge summary fields.');
            testCase.verifyTrue(strlength(string(ui.controls.safe.valueHandle.Value)) > 1, ...
                'CIC workflow should refresh the safety summary field.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.top.Children), 0, ...
                'CIC workflow should draw the top plot.');
            testCase.verifyGreaterThan(numel(ui.controls.plotAxes.axesById.bottom.Children), 0, ...
                'CIC workflow should draw the bottom plot.');
            topAxes = ui.controls.plotAxes.axesById.top;
            bottomAxes = ui.controls.plotAxes.axesById.bottom;
            assertExtremaLabelsAreReadable(topAxes);
            topAxes.XLim = [-1 0];
            topAxes.YLim = [-0.01 0.01];

            driver.chooseFiles('files', secondFixture);
            driver.click('Add DTA files');

            testCase.verifyEqual(char(driver.fileStatus('files')), '2 file(s) loaded');
            testCase.verifyTrue(contains(driver.fileSelection('files'), ...
                'chrono_chronopot_current_pulse_1ms.DTA'), ...
                'CIC append should select the newly added chrono file.');
            testCase.verifyFalse(isequal(topAxes.XLim, [-1 0]), ...
                'CIC append redraw should replace stale manual X limits.');
            testCase.verifyFalse(isequal(topAxes.YLim, [-0.01 0.01]), ...
                'CIC append redraw should replace stale manual Y limits.');

            driver.click('Clear all');
            testCase.verifyEqual(char(driver.fileStatus('files')), 'No files loaded');
            testCase.verifyEmpty(topAxes.Children, ...
                'CIC clear-all should remove stale plot markers and annotations.');
            testCase.verifyEmpty(bottomAxes.Children, ...
                'CIC clear-all should remove stale bottom plot markers and annotations.');
            testCase.verifyEqual(topAxes.XLimMode, 'auto', ...
                'CIC clear-all should restore automatic X limits.');
            testCase.verifyEqual(topAxes.YLimMode, 'auto', ...
                'CIC clear-all should restore automatic Y limits.');
        end
    end
end

function assertCicLayout(h, fig)
    h.assertStandardWorkbenchLayout(fig);
    h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
        'Clear all', 'Export results CSV'});
    h.assertTextsAbsent(fig, {'Refresh plots', 'Swap top / bottom', ...
        'Reset axes'});
    h.assertCheckboxContract(fig, { ...
        'Show debug markers', 'Show window limits', 'Shade pulse windows', ...
        'Use measured Im integration for charge (recommended)'});
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Pt (-0.6 to 0.8 V)', ...
        'PEDOT:PSS (-0.9 to 0.6 V)', 'Custom'}, 1), ...
        h.dropdownGroup({'Metadata first, then auto', 'Metadata only', ...
        'Auto from Im only'}, 1), ...
        h.dropdownGroup({'Cathodic phase', 'Anodic phase', ...
        'Total biphasic'}, 1), ...
        h.dropdownGroup({'mC/cm^2', 'uC/cm^2'}, 1), ...
        h.dropdownGroup({'Time (s)', 'Sample #'}, 2), ...
        h.dropdownGroup({'VT: Vf vs time', 'IT: Im vs time'}, 2)]);
    h.assertDropdownCallbacksPresent(fig);
end

function assertExtremaLabelsAreReadable(ax)
    texts = findall(ax, 'Type', 'text');
    labels = string(get(texts, 'String'));
    if isscalar(texts)
        labels = string(texts.String);
    end
    emc = texts(contains(labels, "Emc ="));
    ema = texts(contains(labels, "Ema ="));
    assert(~isempty(emc) && ~isempty(ema), ...
        'CIC VT plot should label Emc and Ema markers.');
    assert(isWhiteBackground(emc(1)) && isWhiteBackground(ema(1)), ...
        'CIC Emc/Ema labels should have a readable background.');
    assert(~strcmp(emc(1).HorizontalAlignment, ema(1).HorizontalAlignment), ...
        'CIC Emc/Ema labels should be staggered to reduce overlap.');
end

function tf = isWhiteBackground(textHandle)
    color = textHandle.BackgroundColor;
    if ischar(color) || isstring(color)
        tf = strcmp(char(color), 'w');
    else
        tf = isnumeric(color) && isequal(size(color), [1 3]) && ...
            all(abs(color - [1 1 1]) < 1e-12);
    end
end
