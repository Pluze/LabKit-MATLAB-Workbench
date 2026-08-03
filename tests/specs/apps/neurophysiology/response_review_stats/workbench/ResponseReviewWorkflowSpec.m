classdef ResponseReviewWorkflowSpec < matlab.unittest.TestCase
    %RESPONSEREVIEWWORKFLOWSPEC Specify metrics review, export, and restore.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function loadsPreviewsExportsResetsAndRestoresMetrics(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            segmentPath = fullfile(folder, "segments.csv");
            alternateFolder = fullfile(folder, "alternate");
            mkdir(alternateFolder);
            writeSegments(segmentPath);
            backend = struct( ...
                "alert", @(~, ~) [], ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(alternateFolder));
            definition = response_review_stats.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                definition, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("inputFile", string(segmentPath), 1);
            runtime.applyControlValue("preview", "Aligned");
            runtime.invokeAction("exportMetrics");

            defaultFolder = fullfile(folder, "response_review_stats");
            testCase.verifyEqual(height(runtime.State.session.cache.metrics), 2);
            testCase.verifyEqual(height(runtime.State.session.cache.summary), 2);
            testCase.verifyEqual(runtime.State.session.view.previewMode, "Aligned");
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview").Children);
            testCase.verifyTrue(isfile(fullfile(defaultFolder, "response_review_metrics.csv")));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastExport.manifestPath));
            saved = fullfile(folder, "response-review-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.invokeAction("clearOutputFolder");
            runtime.invokeAction("chooseOutputFolder");
            testCase.verifyEqual(runtime.State.session.workflow.outputFolder, string(alternateFolder));
            runtime.invokeAction("resetWorkflow");
            testCase.verifyEmpty(runtime.State.project.inputs.sources);
            testCase.verifyEqual(height(runtime.State.session.cache.metrics), 0);
            runtime.restoreProject(saved);
            testCase.verifyEqual(height(runtime.State.session.cache.metrics), 2);
            clear cleanup
        end
    end
end

function writeSegments(path)
Time_s = (0:.001:.020).';
Signal1 = zeros(size(Time_s));
Signal2 = zeros(size(Time_s));
Signal1(Time_s == .006) = 2;
Signal1(Time_s == .010) = -1;
Signal2(Time_s == .007) = 3;
Signal2(Time_s == .011) = -2;
writetable(table(Time_s, Signal1, Signal2), path);
end
