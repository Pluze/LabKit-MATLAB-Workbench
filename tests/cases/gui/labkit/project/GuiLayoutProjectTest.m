classdef GuiLayoutProjectTest < matlab.uitest.TestCase
    %GUILAYOUTPROJECTTEST Verify project-tool GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_project(testCase)
            setupLabKitTestPath();
            verify_gui_layout_project();
        end
    end
end

function verify_gui_layout_project()
%TEST_GUI_LAYOUT_PROJECT Verify project governance GUI layout contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = h.launchFigure('labkit_ProjectGovernance_app', 'Project Governance');
    h.assertFigureMinimumSize(fig, 1280, 760);
    h.assertComponentCounts(fig, struct('Button', 4, 'Table', 1, ...
        'TextArea', 2));
    h.assertButtonContract(fig, {'Create app', 'Refresh', ...
        'Scan Project Code', 'Create local project'});
    h.assertTabTitles(fig, {'Governance', 'New App', 'Actions', ...
        'Project Code', 'Status', 'Generated Files Preview', 'Details', 'Log'});
    h.assertAnyTableColumns(fig, {'Item', 'Path'});
    h.invokeButton(fig, 'Refresh');
end
