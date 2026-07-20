classdef GuiLayoutResponseReviewStatsTest < matlab.unittest.TestCase
    %GUILAYOUTRESPONSEREVIEWSTATSTEST Verify response-review GUI workflow.

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function response_review_stats_workflow_loads_metrics_and_exports(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            segmentPath = fullfile(folder, 'segments.csv');
            writeSegmentCsv(segmentPath);
            alternateFolder = fullfile(folder, "alternate");
            mkdir(alternateFolder);

            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                response_review_stats.definition(), [], struct( ...
                    "alert", @(~, ~) [], ...
                    "chooseOutputFolder", @(~) ...
                        labkit.app.dialog.Choice(alternateFolder)));
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            ids = ["inputFile", "baselineWindowSec", "noiseWindowSec", ...
                "statusField", "loadMetrics", "resetWorkflow", ...
                "summaryTable", "details", "outputFolder", ...
                "chooseOutputFolder", "clearOutputFolder", ...
                "exportMetrics", "logPanel", "preview"];
            for id = ids
                testCase.verifyEqual(numel(findall(fig, "Tag", id)), 1);
            end
            testCase.verifyEqual( ...
                findall(fig, "Tag", "baselineWindowSec").Value, 0.007);
            testCase.verifyEqual( ...
                findall(fig, "Tag", "baselineWindowSec.end").Value, 0.009);
            testCase.verifyEqual( ...
                findall(fig, "Tag", "noiseWindowSec").Value, 0.007);
            testCase.verifyEqual( ...
                findall(fig, "Tag", "noiseWindowSec.end").Value, 0.009);
            runtime.applyFileSelection('inputFile', segmentPath, 1);

            testCase.verifyEqual( ...
                height(runtime.State.session.cache.metrics), 2);
            testCase.verifyEqual( ...
                height(runtime.State.session.cache.summary), 2);
            defaultOutputFolder = fullfile(folder, "response_review_stats");
            testCase.verifyEqual( ...
                runtime.State.session.workflow.outputFolder, ...
                string(defaultOutputFolder));
            previewAxes = findall(fig, 'Tag', 'preview');
            testCase.verifyNotEmpty(previewAxes.Children);

            runtime.applyControlValue('preview', 'Aligned');
            testCase.verifyEqual( ...
                runtime.State.session.view.previewMode, "Aligned");
            testCase.verifyNotEmpty(previewAxes.Children);

            runtime.invokeAction('exportMetrics');
            outputPath = fullfile( ...
                defaultOutputFolder, 'response_review_metrics.csv');
            testCase.verifyTrue(exist(outputPath, 'file') == 2, ...
                'Response-review workflow should export the metrics CSV.');
            manifestPath = ...
                runtime.State.project.results.lastExport.manifestPath;
            testCase.verifyEqual(string(manifestPath), string(fullfile( ...
                defaultOutputFolder, ...
                "response_review_metrics.labkit.json")));
            testCase.verifyTrue(exist(manifestPath, 'file') == 2, ...
                'Response-review export should include a standard manifest.');

            testCase.verifyFalse(isfield( ...
                runtime.State.project.results.lastExport, 'metrics'), ...
                'Durable export records must not embed metric cache data.');
            projectPath = fullfile(folder, 'response-review-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 2);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'cache'));
            runtime.invokeAction("clearOutputFolder");
            testCase.verifyEqual( ...
                runtime.State.session.workflow.outputFolder, "");
            runtime.invokeAction("chooseOutputFolder");
            testCase.verifyEqual( ...
                runtime.State.session.workflow.outputFolder, ...
                string(alternateFolder));
            runtime.invokeAction("resetWorkflow");
            testCase.verifyEmpty(runtime.State.project.inputs.sources);
            testCase.verifyEqual( ...
                height(runtime.State.session.cache.metrics), 0);
            runtime.restoreProject(projectPath);
            testCase.verifyEqual(height(runtime.State.session.cache.metrics), 2, ...
                'Project reopen should rebuild metric cache from its source.');
            testCase.verifyNotEmpty(previewAxes.Children);
            clear runtimeCleanup
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

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
