classdef GuiLayoutRhsPreviewTest < matlab.unittest.TestCase
    %GUILAYOUTRHSPREVIEWTEST Verify RHS Preview GUI workflow contracts.

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function rhs_preview_workflow_indexes_previews_and_discovers_filter_files(~)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
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

            fig = h.launchFigure('labkit_RHSPreview_app', 'RHS Preview');
            workflow = labkitWorkflowDriver(fig);

            workflow.chooseFiles('rhsFile', string(primaryPath));
            workflow.click('Choose RHS');
            assert(workflow.enabled('refreshPreviewWindow'), ...
                'Refresh Preview should enable after a readable RHS file is selected.');
            assert(workflow.enabled('saveProtocol'), ...
                'Save Protocol Draft should enable after RHS channels are indexed.');
            assert(workflow.previewChildCount('preview') > 0, ...
                'RHS Preview should draw a waveform preview after indexing the synthetic RHS file.');

            summary = workflow.tableData('summaryTable');
            assert(any(strcmp(string(summary(:, 1)), 'RHS file')), ...
                'RHS summary table should include the selected file row.');
            channels = workflow.tableData('previewChannelsTable');
            assert(size(channels, 1) >= 3, ...
                'RHS preview channel table should include indexed amplifier channels.');
            assert(any(contains(string(workflow.textAreaValue('details')), 'C-001')), ...
                'RHS details should expose synthetic amplifier channel names.');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            assert(runtime.definition.contractVersion == 2, ...
                'RHS Preview must execute through Runtime V2.');
            assert(~isfield(runtime.state.project.inputs, 'info'), ...
                'RHS project must not persist decoded header/index data.');
            assert(~isempty(runtime.state.session.cache.index), ...
                'RHS index data should live in session cache.');

            workflow.chooseFiles('rhsFolder', [string(primaryPath); string(secondaryPath)]);
            workflow.click('Add RHS files or folder');
            assert(workflow.enabled('saveFilterRecord'), ...
                'Save Filter Record should enable after RHS filter files are discovered.');
            filterRows = workflow.tableData('fileFilterTable');
            assert(size(filterRows, 1) == 2, ...
                'RHS filter table should include both selected synthetic RHS files.');

            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() removeTempFolder(outputFolder));
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            outputs = ["rhs_protocol_draft.json", "rhs_filter_record.json"];
            outputIndex = 0;
            runtime.request.outputChooser = @chooseOutput;
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            workflow.click('Save Protocol Draft');
            workflow.click('Save Filter Record');
            assert(isfile(fullfile(outputFolder, outputs(1))));
            assert(isfile(fullfile(outputFolder, outputs(2))));
            assert(isfile(fullfile(outputFolder, ...
                'rhs_protocol_draft.labkit.json')));
            assert(isfile(fullfile(outputFolder, ...
                'rhs_filter_record.labkit.json')));

            projectPath = fullfile(outputFolder, 'rhs-preview-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            assert(saved.labkitProject.app.payloadVersion == 2);
            assert(~isfield(saved.labkitProject.payload.inputs, 'index'));
            workflow.click('Reset');
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            assert(workflow.previewChildCount('preview') > 0, ...
                'Project reopen should rebuild the indexed preview cache.');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            filterPaths = rhs_preview.sourceFiles.pathsForRole( ...
                runtime.state.project.inputs.sources, "filterRecording");
            assert(numel(filterPaths) == 2);
            clear outputCleanup;

            function [filename, folderPath] = chooseOutput(~, ~, ~)
                outputIndex = outputIndex + 1;
                filename = char(outputs(outputIndex));
                folderPath = char(outputFolder);
            end
        end
    end
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
