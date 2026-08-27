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

        function resultGenerationAndViewModeOwnViewportRevision(testCase)
            model = struct("sourceIds", "review-a", ...
                "previewMode", "Summary", "plotViewRevision", 0);
            base = response_review_stats.analysisRun.viewportRevision(model);

            testCase.verifyEqual( ...
                response_review_stats.analysisRun.viewportRevision(model), ...
                base);
            model.previewMode = "Aligned";
            testCase.verifyNotEqual( ...
                response_review_stats.analysisRun.viewportRevision(model), ...
                base);
            model = struct("sourceIds", "review-a", ...
                "previewMode", "Summary", "plotViewRevision", 1);
            testCase.verifyNotEqual( ...
                response_review_stats.analysisRun.viewportRevision(model), ...
                base);
            model = struct("sourceIds", "review-b", ...
                "previewMode", "Summary", "plotViewRevision", 0);
            testCase.verifyNotEqual( ...
                response_review_stats.analysisRun.viewportRevision(model), ...
                base);
        end
    end
end
