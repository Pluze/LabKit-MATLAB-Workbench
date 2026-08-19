classdef DicPreprocessPresentationSpec < matlab.unittest.TestCase
    %DICPREPROCESSPRESENTATIONSPEC Specify reader-facing DIC preview detail.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function describesCropAndTransformOperationsWithoutUiTraversal(testCase)
            selection = dic_preprocess.analysisRun.cropSelectionSummary([10.2 20.7 31.5 31.5]);
            transform = dic_preprocess.analysisRun.transformSummary( ...
                [1 0 0; 0 1 0; 2.5 -3.25 1], [12 20 3], [10 18]);

            testCase.verifyEqual(selection{3}, 'Current square ROI: x=10, y=21, size=32 px');
            testCase.verifyEqual(transform{4}, '[1 0 0]');
        end
    end
end
