classdef GuiLayoutRhsPreviewTest < matlab.unittest.TestCase
    %GUILAYOUTRHSPREVIEWTEST Verify RHS Preview GUI workflow contracts.

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function rhs_preview_workflow_indexes_previews_and_discovers_filter_files(testCase)
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

            workflow.chooseFiles('rhsFolder', [string(primaryPath); string(secondaryPath)]);
            workflow.click('Add RHS files or folder');
            assert(workflow.enabled('saveFilterRecord'), ...
                'Save Filter Record should enable after RHS filter files are discovered.');
            filterRows = workflow.tableData('fileFilterTable');
            assert(size(filterRows, 1) == 2, ...
                'RHS filter table should include both selected synthetic RHS files.');
        end
    end
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
