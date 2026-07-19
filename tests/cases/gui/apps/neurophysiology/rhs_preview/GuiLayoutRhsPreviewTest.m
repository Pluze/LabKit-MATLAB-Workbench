classdef GuiLayoutRhsPreviewTest < matlab.unittest.TestCase
    %GUILAYOUTRHSPREVIEWTEST Verify RHS Preview GUI workflow contracts.

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function rhs_preview_workflow_indexes_previews_and_discovers_filter_files(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            primaryPath = fullfile(folder, 'primary.rhs');
            secondaryPath = fullfile(folder, 'secondary.rhs');
            writeSyntheticRhsFixture(primaryPath, struct( ...
                "nBlocks", 3, ...
                "amplifierNames", ["C-001", "C-002", "C-003"]));
            writeSyntheticRhsFixture(secondaryPath, struct( ...
                "nBlocks", 1, ...
                "amplifierNames", "C-004"));

            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() removeTempFolder(outputFolder));
            outputs = ["rhs_protocol_draft.json", "rhs_filter_record.json"];
            outputIndex = 0;
            backend = struct( ...
                "chooseOutputFile", @chooseOutput, ...
                "alert", @(~, ~) []);
            definition = rhs_preview.definition();
            project = definition.ProjectSchema.Create();
            project.inputs.sources = [ ...
                labkit.app.project.sourceRecord( ...
                    "recording-1", "recording", primaryPath, true); ...
                labkit.app.project.sourceRecord( ...
                    "filterRecording-1", "filterRecording", ...
                    primaryPath, true); ...
                labkit.app.project.sourceRecord( ...
                    "filterRecording-2", "filterRecording", ...
                    secondaryPath, true)];
            runtime = definition.createMatlabRuntime(project, backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();

            testCase.verifyNotEmpty(runtime.State.session.cache.index);
            testCase.verifyGreaterThanOrEqual(height( ...
                runtime.State.session.cache.previewChannelRows), 3);
            testCase.verifyEqual(height( ...
                runtime.State.session.cache.filterRows), 2);
            testCase.verifyFalse(isfield( ...
                runtime.State.project.inputs, 'info'));
            previewAxes = findall(fig, 'Tag', 'preview');
            testCase.verifyNotEmpty(previewAxes.Children);

            runtime.invokeAction('saveProtocol');
            runtime.invokeAction('saveFilterRecord');
            assert(isfile(fullfile(outputFolder, outputs(1))));
            assert(isfile(fullfile(outputFolder, outputs(2))));

            projectPath = fullfile(outputFolder, 'rhs-preview-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            assert(saved.labkitProject.app.payloadVersion == 2);
            assert(~isfield(saved.labkitProject.payload.inputs, 'index'));
            runtime.applyFileSelection( ...
                'rhsFile', strings(1, 0), zeros(1, 0));
            runtime.restoreProject(projectPath);
            assert(~isempty(runtime.State.session.cache.index));
            assert(~isempty(previewAxes.Children), ...
                'Project reopen should rebuild the indexed preview cache.');
            filterSources = runtime.State.project.inputs.sources( ...
                string({runtime.State.project.inputs.sources.role}) == ...
                "filterRecording");
            assert(numel(filterSources) == 2);
            clear runtimeCleanup outputCleanup;

            function choice = chooseOutput(~, ~)
                outputIndex = outputIndex + 1;
                choice = labkit.app.dialog.Choice( ...
                    fullfile(outputFolder, outputs(outputIndex)));
            end
        end
    end
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
