classdef FocusStackResultSpec < matlab.unittest.TestCase
    %FOCUSSTACKRESULTSPEC Specify one stable result row per source slice.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function summarizesEverySourceWithTheEffectiveFusionOptions(testCase)
            result = focus_stack.analysisRun.computeFocusStack( ...
                {zeros(16), ones(16)}, struct("focusWindow", 5, ...
                "smoothRadius", 1, "minConfidence", .05));

            summary = focus_stack.resultFiles.buildSummaryTable( ...
                result, ["slice_a.png"; "slice_b.png"]);

            testCase.verifyEqual(height(summary), 2);
            testCase.verifyEqual(summary.SourceImage(1), "slice_a.png");
            testCase.verifyEqual(summary.DetailScale_px(1), result.focusWindow);
            testCase.verifyEqual(summary.BlendRadius_px(1), result.smoothRadius);
            testCase.verifyEqual(sum(summary.SelectedPixelFraction), 1, AbsTol=1e-12);
        end
    end
end
