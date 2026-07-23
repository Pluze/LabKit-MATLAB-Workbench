classdef ResponseReviewPresentationSpec < matlab.unittest.TestCase
    %RESPONSEREVIEWPRESENTATIONSPEC Specify GUI-free response summary values.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsSummaryRowsAndDetailLinesForAnEmptyReview(testCase)
            summary = response_review_stats.analysisRun.summaryTableData(struct());
            details = response_review_stats.analysisRun.detailLines(struct());

            testCase.verifyTrue(iscell(summary));
            testCase.verifyGreaterThanOrEqual(size(summary, 1), 4);
            testCase.verifyEqual(size(summary, 2), 2);
            testCase.verifyTrue(iscell(details));
            testCase.verifyNotEmpty(details);
        end
    end
end
