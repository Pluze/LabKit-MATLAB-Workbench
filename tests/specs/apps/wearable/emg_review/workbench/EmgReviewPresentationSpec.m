classdef EmgReviewPresentationSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:presentation','Env:headless'})
        function overviewKeepsNarrowExcursionsInTimeOrder(testCase)
            % Single-sample extrema must survive when the preview is reduced.
            values = zeros(10001, 1);
            time = (0:numel(values) - 1).' / 1000;
            values([5001 5002]) = [12 -9];
            preview = emg_review.sourceFiles.waveformPreview(time, values);
            testCase.verifyLessThan(numel(preview.values), numel(values));
            testCase.verifyEqual(preview.time(preview.values == 12), 5);
            testCase.verifyEqual(preview.time(preview.values == -9), 5.001);
            testCase.verifyTrue(issorted(preview.time));
        end
    end
end
