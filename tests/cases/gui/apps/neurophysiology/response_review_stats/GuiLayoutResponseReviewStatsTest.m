classdef GuiLayoutResponseReviewStatsTest < matlab.uitest.TestCase
    %GUILAYOUTRESPONSEREVIEWSTATSTEST Verify response-review GUI workflow.

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function response_review_stats_workflow_loads_metrics_and_exports(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            segmentPath = fullfile(folder, 'segments.csv');
            writeSegmentCsv(segmentPath);

            fig = h.launchFigure('labkit_ResponseReviewStats_app', ...
                'Response Review Stats');
            driver = labkitWorkflowDriver(fig);
            driver.chooseFiles('inputFile', segmentPath);

            driver.click('Choose input');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.inputFile.status.Value), ...
                'segments.csv'), ...
                'Response-review workflow should show the selected segment CSV.');
            testCase.verifyTrue(contains(string(ui.controls.statusField.valueHandle.Value), ...
                'Loaded 2 metric row'), ...
                'Response-review workflow should auto-load metrics after input selection.');
            data = driver.tableData('summaryTable');
            testCase.verifyTrue(rowHasValue(data, 'Metrics', '2'), ...
                'Response-review summary should include measured metric rows.');
            testCase.verifyTrue(rowHasValue(data, 'Summary groups', '2'), ...
                'Response-review summary should include one group per segment.');
            testCase.verifyTrue(any(contains(string(driver.textAreaValue('details')), ...
                'Groups: 2')), ...
                'Response-review details should summarize metric groups.');
            testCase.verifyGreaterThan(driver.previewChildCount('preview'), 0, ...
                'Response-review workflow should draw the summary preview.');
            testCase.verifyTrue(driver.enabled('exportMetrics'), ...
                'Response-review export should enable after metrics load with a default output folder.');

            driver.dropdown('Aligned');
            testCase.verifyGreaterThan(driver.previewChildCount('preview'), 0, ...
                'Response-review workflow should redraw the aligned preview.');

            driver.click('Export Metrics');
            outputPath = fullfile(folder, 'response_review_stats', ...
                'response_review_metrics.csv');
            testCase.verifyTrue(exist(outputPath, 'file') == 2, ...
                'Response-review workflow should export the metrics CSV.');
        end
    end
end

function writeSegmentCsv(filepath)
    Time_s = (0:0.001:0.020).';
    Signal1 = zeros(size(Time_s));
    Signal2 = zeros(size(Time_s));
    Signal1(Time_s == 0.006) = 2;
    Signal1(Time_s == 0.010) = -1;
    Signal2(Time_s == 0.007) = 3;
    Signal2(Time_s == 0.011) = -2;
    T = table(Time_s, Signal1, Signal2);
    writetable(T, filepath);
end

function tf = rowHasValue(data, metric, value)
    tf = any(strcmp(string(data(:, 1)), metric) & strcmp(string(data(:, 2)), value));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
