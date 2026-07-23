classdef FocusStackPresentationSpec < matlab.unittest.TestCase
    %FOCUSSTACKPRESENTATIONSPEC Specify focus result reader-facing rows.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsAStableInitialResultTable(testCase)
            rows = focus_stack.focusPreview.initialResultTable();
            presets = focus_stack.focusPreview.fusionPresetItems();

            testCase.verifyTrue(iscell(rows));
            testCase.verifyEqual(rows{1, 1}, 'Input images');
            testCase.verifyTrue(any(presets == "Balanced"));
        end
    end
end
