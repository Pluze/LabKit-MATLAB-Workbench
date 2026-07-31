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

        function detailsPreserveCoverageAndRegistrationOrder(testCase)
            result = struct( ...
                "method", "Synthetic", ...
                "imageWidth", 20, "imageHeight", 10, ...
                "channelCount", 3, "resizedCount", 0, ...
                "focusWindow", 5, "smoothRadius", 2, ...
                "minConfidence", .1, "inputCount", 2, ...
                "focusCoverage", [.25 .75]);

            lines = focus_stack.focusPreview.details( ...
                result, ["first.png" "second.png"], ...
                {"registered 2 images"});

            testCase.verifyEqual(lines{6}, ...
                '  1. first.png: 25.00%');
            testCase.verifyEqual(lines{8}, 'Registration:');
            testCase.verifyEqual(lines{9}, "registered 2 images");
        end
    end
end
