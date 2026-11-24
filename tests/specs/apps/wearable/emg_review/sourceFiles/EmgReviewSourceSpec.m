classdef EmgReviewSourceSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:source','Env:headless'})
        function usesChannelAndRateFromTheSourceAndClearsPreviousMarks(testCase)
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            path = fullfile(folder,"emg.csv");
            time_s = (0:7).' / 100;
            Lead = (1:8).';
            Reference = -Lead;
            writetable(table(time_s, Lead, Reference), path);
            session = emg_review.sourceFiles.readSource(path);
            testCase.verifyEqual(session.band, "As recorded");
            testCase.verifyEqual(session.signal.values, Lead);
            session.pairs = [0 1; 2 3];
            session = emg_review.sourceFiles.selectChannel(session, "Reference");
            testCase.verifyEqual(session.signal.values, Reference);
            testCase.verifyEqual(session.signal.fs, 100, AbsTol=1e-10);
            testCase.verifyEqual(session.pairs, [0 0]);
        end
    end
end
