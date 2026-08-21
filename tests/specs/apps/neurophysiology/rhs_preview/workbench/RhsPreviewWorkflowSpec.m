classdef RhsPreviewWorkflowSpec < matlab.unittest.TestCase
    %RHSPREVIEWWORKFLOWSPEC Specify RHS indexing, preview, and record export.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function indexesPreviewsExportsAndRestoresSyntheticRhs(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            project = rhsPreviewWorkflowProject(string(folder));
            primary = fullfile(folder, "acquisition", "primary.rhs");
            repeat = fullfile(folder, "acquisition", "repeat.rhs");
            protocolPath = fullfile(folder, "rhs_protocol_draft.json");
            filterPath = fullfile(folder, "rhs_filter_record.json");
            project.inputs.sources = [project.inputs.sources(:); ...
                labkit.app.source.record("filter-1", "filterRecording", primary); ...
                labkit.app.source.record("filter-2", "filterRecording", repeat)];
            backend = struct( ...
                "chooseOutputFile", @(~, defaultPath) chooseOutput( ...
                    defaultPath, protocolPath, filterPath), ...
                "alert", @(~, ~) []);
            definition = rhs_preview.definition();
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
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
            testCase.verifyTrue(isfile(runtime.State.project.results.lastProtocolExport.outputPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastFilterExport.outputPath));
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
