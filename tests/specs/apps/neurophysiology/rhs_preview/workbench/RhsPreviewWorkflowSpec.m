classdef RhsPreviewWorkflowSpec < matlab.unittest.TestCase
    %RHSPREVIEWWORKFLOWSPEC Specify RHS indexing, preview, and record export.

    methods (Test, TestTags = {'Contract:workflow', 'Env:hidden-gui'})
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

            runtime.applyFileSelection("rhsFile", string(primary), 1);
            runtime.applyFileSelection("rhsFolder", ...
                [string(primary); string(repeat)], [1 2]);
            runtime.applyFileSelection("protocolFile", ...
                string(project.inputs.sources(2).path), 1);
            runtime.applyControlValue("channelFamily", "amplifier");
            runtime.applyControlValue("maxPreviewChannels", 2);
            runtime.applyControlValue("windowStartPanner", .001);
            runtime.invokeAction("refreshPreviewWindow");
            previewTable = findall(figureValue, "Tag", "previewChannelsTable");
            previewData = previewTable.Data;
            previousLabel = previewData{1, 3};
            previewData{1, 3} = "Primary trace";
            runtime.applyTableEdit("previewChannelsTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=3, ...
                    PreviousValue=previousLabel, NewValue="Primary trace", ...
                    Data=previewData));
            filterTable = findall(figureValue, "Tag", "fileFilterTable");
            filterData = filterTable.Data;
            previousComment = filterData{1, 3};
            filterData{1, 3} = "keep";
            runtime.applyTableEdit("fileFilterTable", ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=3, ...
                    PreviousValue=previousComment, NewValue="keep", ...
                    Data=filterData));
            runtime.invokeAction("refreshFolderFiles");
            time = runtime.State.session.cache.preview.timeSec;
            roi = [time(1), time(end)];
            runtime.applyInteraction("previewRange", "interactionChanged", roi);
            testCase.verifyEqual(runtime.State.session.view.roiSec, roi, ...
                AbsTol=1e-12);
            originalDuration = runtime.State.session.view.windowDurationSec;
            runtime.applyInteraction("previewRange", "scrolled", ...
                labkit.app.event.IntervalScroll(Anchor=mean(roi), Count=-1));
            testCase.verifyLessThan( ...
                runtime.State.session.view.windowDurationSec, originalDuration);
            runtime.applyInteraction("previewRange", "interactionChanged", roi);
            runtime.invokeAction("zoomToRoiWindow");
            runtime.invokeAction("saveProtocol");
            runtime.invokeAction("saveFilterRecord");

            testCase.verifyGreaterThanOrEqual( ...
                height(runtime.State.session.cache.previewChannelRows), 3);
            testCase.verifyEqual(height(runtime.State.session.cache.filterRows), 2);
            zoomedRoi = runtime.State.session.view.roiSec;
            testCase.verifyTrue(all(isfinite(zoomedRoi)));
            testCase.verifyLessThan(diff(zoomedRoi), diff(roi));
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "preview").Children);
            testCase.verifyTrue(isfile(protocolPath));
            testCase.verifyTrue(isfile(filterPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastProtocolExport.outputPath));
            testCase.verifyTrue(isfile(runtime.State.project.results.lastFilterExport.outputPath));
            runtime.invokeAction("resetWorkflow");
            testCase.verifyEmpty(runtime.State.session.cache.preview);
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
