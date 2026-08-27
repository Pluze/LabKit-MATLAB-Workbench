classdef NerveResponseWorkflowSpec < matlab.unittest.TestCase
    %NERVERESPONSEWORKFLOWSPEC Specify filtered RHS analysis and export.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
        function analyzesExportsResetsAndRestoresSyntheticSession(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = nerveResponseWorkflowProject(string(folder));
            protocolPath = project.inputs.sources(2).path;
            definition = nerve_response_analysis.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, project, struct( ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []), ...
                journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("sessionFile", ...
                project.inputs.sources(1).path, 1);
            runtime.applyFileSelection("protocolFile", protocolPath, 1);
            runtime.applyControlValue("maxRecordings", 2);
            runtime.applyControlValue("maxDurationSec", .07);
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("runAnalysis");
            runtime.applyControlValue("preview", "Issues");
            runtime.invokeAction("exportAnalysis");

            outputFolder = runtime.State.session.workflow.outputFolder;
            analysis = runtime.State.session.cache.analysis;
            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyGreaterThan(analysis.analyzedCount, 0);
            testCase.verifyEqual( ...
                runtime.State.session.cache.plotViewRevision, 1);
            testCase.verifyEqual(runtime.State.session.view.previewMode, "Issues");
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview").Children);
            testCase.verifyTrue(isfile(fullfile(outputFolder, "nerve_response_analysis.json")));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastExport.outputPath));
            exportedPath = runtime.State.project.results.lastExport.outputPath;
            runtime.invokeAction("clearOutputFolder");
            testCase.verifyEqual(runtime.State.session.workflow.outputFolder, "");
            runtime.invokeAction("resetWorkflow");
            testCase.verifyEmpty(runtime.State.session.cache.analysis);
            testCase.verifyTrue(isfile(exportedPath));
            clear cleanup
        end
    end
end
