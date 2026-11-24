classdef EmgReviewRegionsSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:source','Env:headless'})
        function marksQuietAndActiveWindowsWithoutReusingOtherPairs(testCase)
            % Four exact, zero-mean amplitude blocks give unique extrema.
            values = repmat([1;-1;1;-1],1,4) .* [1 10 2 6];
            testCase.verifyEqual(emg_review.regions.suggest( ...
                values(:) + 100, 4, 0, 1, zeros(0,2)), [0 1]);
            testCase.verifyEqual(emg_review.regions.suggest( ...
                values(:), 4, 0, 1, [0 1]), [2 3]);
            testCase.verifyError(@() emg_review.regions.suggest( ...
                values(:), 4, 0, 1, [0 2; 1 3]), "emg_review:NoUnusedWindows");
        end
    end
end
