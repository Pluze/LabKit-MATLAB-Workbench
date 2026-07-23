classdef DicPreprocessPresentationSpec < matlab.unittest.TestCase
    %DICPREPROCESSPRESENTATIONSPEC Specify reader-facing DIC preview detail.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function describesCropAndTransformOperationsWithoutUiTraversal(testCase)
            selection = dic_preprocess.analysisRun.cropSelectionSummary([10.2 20.7 31.5 31.5]);
            transform = dic_preprocess.analysisRun.transformSummary( ...
                [1 0 0; 0 1 0; 2.5 -3.25 1], [12 20 3], [10 18]);
            state = dic_preprocess.maskEditing.maskEditControlState(true, ...
                [1 1; 2 2; 3 1], uint8([0 255]), ...
                struct('maskImage', {uint8(1)}, 'maskPoints', {[1 2]}, ...
                'description', {'mask'}));

            testCase.verifyEqual(selection{3}, 'Current square ROI: x=10, y=21, size=32 px');
            testCase.verifyEqual(transform{4}, '[1 0 0]');
            testCase.verifyEqual(state.preview, 'on');
            testCase.verifyEqual(state.undoMaskEdit, 'on');
        end
    end
end
