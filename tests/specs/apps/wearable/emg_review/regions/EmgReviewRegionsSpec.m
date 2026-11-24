classdef EmgReviewRegionsSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:source','Env:headless'})
        function selectsOneWindowPerBurstAndUsesItsPrecedingQuietInterval(testCase)
            fs = 100;
            % Three quiet/activity cycles. The tail is quieter than all
            % preceding baselines, and the second burst is the strongest.
            phase = repmat([-1;1], fs, 1);
            values = phase .* [2 8 8 3 14 2 9 1];
            args = {values(:), fs, 0, 1};
            empty = zeros(0, 2);
            testCase.verifyEqual(emg_review.regions.suggest(args{:}, empty), [0.5 3.5]);
            testCase.verifyEqual(emg_review.regions.suggest(args{:}, [0 0; 0.5 3.5]), [6.5 8.5]);
            testCase.verifyEqual(emg_review.regions.suggest(args{:}, [0.5 3.5; 6.5 8.5]), [10.5 12.5]);
            testCase.verifyError(@() emg_review.regions.suggest(args{:}, ...
                [0.5 3.5; 6.5 8.5; 10.5 12.5]), "emg_review:NoDistinctPair");
        end

        function rejectsIsolatedImpulsesAndStationarySignal(testCase)
            fs = 100;
            values = repmat([-1;1], 4 * fs, 1);
            values(350) = 1000;
            testCase.verifyError(@() emg_review.regions.suggest(values, fs, 0, 1, ...
                zeros(0, 2)), "emg_review:NoDistinctPair");
        end
    end
end
