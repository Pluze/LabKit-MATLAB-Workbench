classdef NerveResponseWorkflowSpec < matlab.unittest.TestCase
    %NERVERESPONSEWORKFLOWSPEC Specify filtered RHS analysis and export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function analyzesExportsResetsAndRestoresSyntheticSession(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = nerve_response_analysis.syntheticInputs.writeSamplePack(context);
            definition = nerve_response_analysis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, pack.InitialProject, struct("alert", @(~, ~) []), ...
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
            testCase.verifyTrue(isfile(runtime.State.project.results.lastExport.manifestPath));
            saved = fullfile(outputFolder, "nerve-response-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.invokeAction("resetWorkflow");
            testCase.verifyEmpty(runtime.State.session.cache.filterRecord);
            runtime.restoreProject(saved);
            testCase.verifyNotEmpty(runtime.State.session.cache.filterRecord);
            testCase.verifyEmpty(runtime.State.session.cache.analysis);
            runtime.invokeAction("runAnalysis");
            testCase.verifyGreaterThan(runtime.State.session.cache.analysis.analyzedCount, 0);
            clear cleanup
        end
    end
end
