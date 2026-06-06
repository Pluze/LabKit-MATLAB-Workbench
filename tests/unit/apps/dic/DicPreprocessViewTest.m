classdef DicPreprocessViewTest < matlab.unittest.TestCase
    %DICPREPROCESSVIEWTEST Verify GUI-free DIC preprocess view helpers.

    methods (Test, TestTags = {'Unit'})
        function buildSummaryReportsUnloadedState(testCase)
            setupLabKitTestPath();

            state = baseState();

            lines = dic_preprocess.view.buildSummary(state);

            testCase.verifyEqual(lines, { ...
                'Reference: none', ...
                'Moving: none', ...
                'Current pair: not loaded', ...
                'Undo steps: 0', ...
                'Last aligned image: not generated', ...
                'ROI mask: not drawn'});
        end

        function buildSummaryReportsCurrentPairAndDerivedState(testCase)
            setupLabKitTestPath();

            state = baseState();
            state.referencePath = "reference.png";
            state.movingPath = "moving.png";
            state.currentReferenceImage = zeros(12, 20, 3, 'uint8');
            state.currentMovingImage = zeros(10, 18, 'uint8');
            state.alignedImage = zeros(10, 18, 'uint8');
            state.maskImage = uint8([0 1; 1 0]);
            state.history = struct( ...
                'reference', {[] []}, ...
                'moving', {[] []}, ...
                'aligned', {[] []}, ...
                'cropReference', {[] []}, ...
                'cropMoving', {[] []}, ...
                'maskImage', {[] []}, ...
                'maskPoints', {[] []}, ...
                'description', {'alignment', 'crop'});

            lines = dic_preprocess.view.buildSummary(state);

            testCase.verifyEqual(lines, { ...
                'Reference: reference.png', ...
                'Moving: moving.png', ...
                'Current pair: reference 12 x 20, moving 10 x 18', ...
                'Undo steps: 2', ...
                'Last aligned image: available', ...
                'ROI mask: available'});
        end

        function cropSummariesPreserveDetailText(testCase)
            setupLabKitTestPath();

            selection = dic_preprocess.view.cropSelectionSummary([10.2 20.7 31.5 31.5]);
            applied = dic_preprocess.view.cropSummary([1.5 2.5 30 30]);

            testCase.verifyEqual(selection, { ...
                'Active crop source: current reference and current moving images', ...
                'Move or resize the ROI on the current reference preview, then click Apply ROI crop.', ...
                'Current square ROI: x=10, y=21, size=32 px'});
            testCase.verifyEqual(applied, { ...
                'Crop source: current reference and current moving images', ...
                'Crop rectangle: x=1.5, y=2.5, width=30, height=30'});
        end

        function transformSummaryFormatsMatrixRows(testCase)
            setupLabKitTestPath();

            tform = affine2d([1 0 0; 0 1 0; 2.5 -3.25 1]);

            lines = dic_preprocess.view.transformSummary(tform, [12 20 3], [10 18]);

            testCase.verifyEqual(lines, { ...
                'Reference size: 12 x 20', ...
                'Moving size: 10 x 18', ...
                'Rigid transform matrix:', ...
                '[1 0 0]', ...
                '[0 1 0]', ...
                '[2.5 -3.25 1]'});
        end

        function previewRequestBuildsSelectedPreviewImages(testCase)
            setupLabKitTestPath();

            state = baseState();
            state.currentReferenceImage = uint8([0 10; 20 30]);
            state.currentMovingImage = uint8([30 20; 10 0]);
            state.referenceImage = uint8(ones(2, 2));
            state.movingImage = uint8(2 .* ones(2, 2));
            state.maskImage = uint8([0 255; 255 0]);

            overlay = dic_preprocess.view.previewRequest(state, 'False-color overlay');
            original = dic_preprocess.view.previewRequest(state, 'Original pair');
            mask = dic_preprocess.view.previewRequest(state, 'ROI mask');

            testCase.verifyEqual(overlay.topTitle, "Current reference");
            testCase.verifyEqual(overlay.bottomTitle, "False-color overlay");
            testCase.verifySize(overlay.bottomImage, [2 2 3]);
            testCase.verifyEqual(original.topImage, state.referenceImage);
            testCase.verifyEqual(original.bottomTitle, "Original moving");
            testCase.verifyEqual(mask.bottomImage(:, :, 1), state.maskImage);
            testCase.verifyEqual(mask.bottomTitle, "ROI mask");
        end

        function maskEditControlStateAndDraftDetailsMatchAnchorState(testCase)
            setupLabKitTestPath();

            emptyState = dic_preprocess.view.maskEditControlState(true, ...
                zeros(0, 2), [], struct('maskImage', {}, ...
                'maskPoints', {}, 'description', {}));
            boundaryState = dic_preprocess.view.maskEditControlState(true, ...
                [1 1; 2 2; 3 1], uint8([0 255]), ...
                struct('maskImage', {uint8(1)}, ...
                'maskPoints', {[1 2]}, 'description', {'mask'}));
            emptyDetails = dic_preprocess.view.maskDraftDetails(zeros(0, 2));
            boundaryDetails = dic_preprocess.view.maskDraftDetails([1 1; 2 2; 3 1]);

            testCase.verifyEqual(emptyState.addBoundary, 'off');
            testCase.verifyEqual(emptyState.undoPoint, 'off');
            testCase.verifyEqual(boundaryState.preview, 'on');
            testCase.verifyEqual(boundaryState.addBoundary, 'on');
            testCase.verifyEqual(boundaryState.undoMaskEdit, 'on');
            testCase.verifyEqual(emptyDetails, { ...
                'Mask ROI anchors: 0. Need at least 3 anchors to form a closed ROI boundary.'});
            testCase.verifyEqual(boundaryDetails, { ...
                'Mask ROI anchors: 3. Preview, Add to mask, or Subtract from mask.'});
            testCase.verifyEqual(dic_preprocess.view.onOff(true), 'on');
            testCase.verifyEqual(dic_preprocess.view.onOff(false), 'off');
        end
    end
end

function state = baseState()
    state = struct();
    state.referencePath = "";
    state.movingPath = "";
    state.currentReferenceImage = [];
    state.currentMovingImage = [];
    state.history = struct('reference', {}, 'moving', {}, 'aligned', {}, ...
        'cropReference', {}, 'cropMoving', {}, 'maskImage', {}, ...
        'maskPoints', {}, 'description', {});
    state.alignedImage = [];
    state.maskImage = [];
    state.referenceImage = [];
    state.movingImage = [];
end
