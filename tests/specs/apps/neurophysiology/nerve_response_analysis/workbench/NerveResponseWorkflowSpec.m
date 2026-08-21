classdef NerveResponseWorkflowSpec < matlab.unittest.TestCase
    %NERVERESPONSEWORKFLOWSPEC Specify filtered RHS analysis and export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function analyzesExportsResetsAndRestoresSyntheticSession(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = nerveResponseWorkflowProject(string(folder));
            definition = nerve_response_analysis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, project, struct("alert", @(~, ~) []), ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.invokeAction("runAnalysis");
            runtime.applyControlValue("preview", "Issues");
            runtime.invokeAction("exportAnalysis");

            outputFolder = runtime.State.session.workflow.outputFolder;
            analysis = runtime.State.session.cache.analysis;
            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyGreaterThan(analysis.analyzedCount, 0);
            testCase.verifyEqual(runtime.State.session.view.previewMode, "Issues");
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview").Children);
            testCase.verifyTrue(isfile(fullfile(outputFolder, "nerve_response_analysis.json")));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastExport.outputPath));
            clear cleanup
        end
    end
end
