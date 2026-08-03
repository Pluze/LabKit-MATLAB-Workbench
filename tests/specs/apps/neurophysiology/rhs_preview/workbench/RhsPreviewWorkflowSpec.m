classdef RhsPreviewWorkflowSpec < matlab.unittest.TestCase
    %RHSPREVIEWWORKFLOWSPEC Specify RHS indexing, preview, and record export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function indexesPreviewsExportsAndRestoresSyntheticRhs(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.synthetic.Context(folder);
            pack = rhs_preview.syntheticInputs.writeSamplePack(context);
            primary = context.samplePath("rhs_preview/acquisition/representative_primary.rhs");
            repeat = context.samplePath("rhs_preview/acquisition/representative_repeat.rhs");
            protocolPath = context.outputPath("rhs_protocol_draft.json");
            filterPath = context.outputPath("rhs_filter_record.json");
            project = pack.InitialProject;
            project.inputs.sources = [project.inputs.sources(:); ...
                context.sourceRecord("filter-1", "filterRecording", primary, true); ...
                context.sourceRecord("filter-2", "filterRecording", repeat, true)];
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, protocolPath, filterPath), ...
                "alert", @(~, ~) []);
            definition = rhs_preview.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                definition, project, backend, journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyControlValue("maxPreviewChannels", 2);
            time = runtime.State.session.cache.preview.timeSec;
            roi = [time(1), time(end)];
            runtime.applyInteraction("previewRange", "interactionChanged", roi);
            runtime.invokeAction("zoomToRoiWindow");
            runtime.invokeAction("saveProtocol");
            runtime.invokeAction("saveFilterRecord");

            testCase.verifyGreaterThanOrEqual( ...
                height(runtime.State.session.cache.previewChannelRows), 3);
            testCase.verifyEqual(height(runtime.State.session.cache.filterRows), 2);
            testCase.verifyEqual(runtime.State.session.view.roiSec, roi, AbsTol=1e-12);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview").Children);
            testCase.verifyTrue(isfile(protocolPath));
            testCase.verifyTrue(isfile(filterPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastProtocolExport.manifestPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastFilterExport.manifestPath));
            saved = fullfile(folder, "rhs-preview-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.invokeAction("resetWorkflow");
            testCase.verifyEmpty(runtime.State.session.cache.index);
            runtime.restoreProject(saved);
            testCase.verifyNotEmpty(runtime.State.session.cache.index);
            clear cleanup
        end
    end
end

function choice = chooseOutput(defaultPath, protocolPath, filterPath)
if contains(string(defaultPath), "filter", IgnoreCase=true)
    choice = labkit.app.dialog.Choice(filterPath);
else
    choice = labkit.app.dialog.Choice(protocolPath);
end
end
