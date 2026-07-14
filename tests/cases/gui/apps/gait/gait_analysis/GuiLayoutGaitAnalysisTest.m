classdef GuiLayoutGaitAnalysisTest < matlab.unittest.TestCase
    %GUILAYOUTGAITANALYSISTEST Verify Gait Analysis GUI launch and layout contract.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function gait_analysis_launches_with_expected_controls(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            [fig, debug] = labkit_GaitAnalysis_app("debug");
            drawnow;

            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Open pose file', 'Run analysis', ...
                'Choose output folder', 'Export CSV set'});
            h.assertTabTitles(fig, {'Source', 'Roles + Detection', ...
                'Results + Export', 'Log'});
            h.assertDropdownGroups(fig, h.dropdownGroup({'Trajectory', 'Angles', 'Steps'}, 1));
            testCase.verifyTrue(debug.enabled && debug.traceEnabled);
            assertAnyTextAreaContains(h, fig, 'Gait analysis debug trace enabled', ...
                'Debug trace should be mirrored into the visible Log tab.');
        end
    end
end
