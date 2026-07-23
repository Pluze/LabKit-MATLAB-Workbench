classdef ResponseReviewSourceSpec < matlab.unittest.TestCase
    %RESPONSEREVIEWSOURCESPEC Specify accepted response-segment CSV shapes.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function parsesOneSharedTimeColumnIntoNamedFiniteSegments(testCase)
            source = table([0; .1; .2; NaN], [1; 2; 3; 4], [4; 5; 6; 7], ...
                'VariableNames', {'Time_s', 'CP', 'TA'});

            segments = response_review_stats.sourceFiles.parseSegmentTable(source);

            testCase.verifyEqual(string({segments.name}), ["CP" "TA"]);
            testCase.verifyEqual(segments(1).timeSec, [0; .1; .2]);
            testCase.verifyEqual(segments(2).values, [4; 5; 6]);
        end
    end
end
