classdef ResponseReviewResultSpec < matlab.unittest.TestCase
    %RESPONSEREVIEWRESULTSPEC Specify stable response metric CSV output.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function writesMetricColumnsWithoutChangingTheirValues(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            destination = fullfile(folder, 'metrics.csv');
            metrics = table(["cp"; "ta"], [3; 2], ...
                'VariableNames', {'SegmentName', 'PeakToPeak'});

            written = response_review_stats.resultFiles.writeMetricsCsv(metrics, destination);
            restored = readtable(destination, TextType="string");

            testCase.verifyEqual(written, string(destination));
            testCase.verifyEqual(restored.Properties.VariableNames, ...
                {'SegmentName', 'PeakToPeak'});
            testCase.verifyEqual(restored.PeakToPeak, [3; 2]);
        end
    end
end
