classdef NerveResponsePresentationSpec < matlab.unittest.TestCase
    %NERVERESPONSEPRESENTATIONSPEC Specify GUI-free analysis review text.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsStableEmptyReviewCountsAndGuidance(testCase)
            summary = nerve_response_analysis.analysisRun.summaryTableData(struct());
            details = nerve_response_analysis.analysisRun.detailLines(struct());

            testCase.verifyEqual(size(summary, 2), 2);
            testCase.verifyTrue(any(string(summary(:, 1)) == "Recordings"));
            testCase.verifyEqual(details{1}, 'No filter record has been analyzed.');
        end
    end
end
