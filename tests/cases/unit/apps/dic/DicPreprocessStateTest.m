classdef DicPreprocessStateTest < matlab.unittest.TestCase
    %DICPREPROCESSSTATETEST Verify GUI-free DIC preprocess state helpers.

    methods (Test, TestTags = {'Unit'})
        function appendEditHistorySkipsMissingImagePair(testCase)
            setupLabKitTestPath();

            state = baseState();

            [history, appended] = dic_preprocess.state.appendEditHistory( ...
                state.history, state, 'crop');

            testCase.verifyFalse(appended);
            testCase.verifyEmpty(history);
        end

        function setLoadedImageAndHasImagePairTrackCurrentPair(testCase)
            setupLabKitTestPath();

            state = baseState();
            state = dic_preprocess.state.setLoadedImage( ...
                state, 'reference', "reference.png", uint8(1));

            testCase.verifyEqual(state.referencePath, "reference.png");
            testCase.verifyEqual(state.currentReferenceImage, uint8(1));
            testCase.verifyFalse(dic_preprocess.state.hasImagePair(state));

            state = dic_preprocess.state.setLoadedImage( ...
                state, 'moving', "moving.png", uint8(2));

            testCase.verifyEqual(state.movingPath, "moving.png");
            testCase.verifyEqual(state.currentMovingImage, uint8(2));
            testCase.verifyTrue(dic_preprocess.state.hasImagePair(state));
        end

        function appendEditHistoryCapturesAndTrimsSnapshots(testCase)
            setupLabKitTestPath();

            state = baseState();
            state.currentReferenceImage = uint8(ones(2, 3));
            state.currentMovingImage = uint8(2 .* ones(2, 3));
            state.alignedImage = uint8(3 .* ones(2, 3));
            state.cropReference = uint8(4 .* ones(1, 2));
            state.cropMoving = uint8(5 .* ones(1, 2));
            state.maskImage = uint8([0 255]);
            state.maskPoints = [1 2; 3 4];

            history = state.history;
            for k = 1:3
                [history, appended] = dic_preprocess.state.appendEditHistory( ...
                    history, state, sprintf('step%d', k), 2);
                testCase.verifyTrue(appended);
            end

            testCase.verifyEqual(numel(history), 2);
            testCase.verifyEqual({history.description}, {'step2', 'step3'});
            testCase.verifyEqual(history(end).reference, state.currentReferenceImage);
            testCase.verifyEqual(history(end).maskPoints, state.maskPoints);
        end

        function appendMaskHistoryCapturesAndTrimsSnapshots(testCase)
            setupLabKitTestPath();

            history = struct('maskImage', {}, 'maskPoints', {}, 'description', {});
            for k = 1:4
                history = dic_preprocess.state.appendMaskHistory( ...
                    history, uint8(k), [k k+1], sprintf('mask%d', k), 3);
            end

            testCase.verifyEqual(numel(history), 3);
            testCase.verifyEqual({history.description}, {'mask2', 'mask3', 'mask4'});
            testCase.verifyEqual(history(end).maskImage, uint8(4));
            testCase.verifyEqual(history(end).maskPoints, [4 5]);
        end

        function maskCanvasInitializesFromReferenceSize(testCase)
            setupLabKitTestPath();

            emptyCanvas = dic_preprocess.state.maskCanvas([], zeros(3, 4, 3, 'uint8'));
            existingCanvas = dic_preprocess.state.maskCanvas(uint8([0 255]), zeros(3, 4));

            testCase.verifyEqual(emptyCanvas, zeros(3, 4, 'uint8'));
            testCase.verifyEqual(existingCanvas, uint8([0 255]));
        end

        function resetForNewInputRestoresLoadedOriginalsAndClearsDerivedState(testCase)
            setupLabKitTestPath();

            state = populatedState();
            reset = dic_preprocess.state.resetForNewInput(state);

            testCase.verifyEqual(reset.currentReferenceImage, state.referenceImage);
            testCase.verifyEqual(reset.currentMovingImage, state.movingImage);
            testCase.verifyEmpty(reset.alignedImage);
            testCase.verifyEmpty(reset.cropReference);
            testCase.verifyEmpty(reset.cropMoving);
            testCase.verifyEmpty(reset.cropRect);
            testCase.verifyEmpty(reset.maskImage);
            testCase.verifyEmpty(reset.maskPoints);
            testCase.verifyEmpty(reset.history);
        end

        function resetToOriginalsKeepsLoadedPathsAndClearsDerivedMaskState(testCase)
            setupLabKitTestPath();

            state = populatedState();
            reset = dic_preprocess.state.resetToOriginals(state);

            testCase.verifyEqual(reset.referencePath, state.referencePath);
            testCase.verifyEqual(reset.currentReferenceImage, state.referenceImage);
            testCase.verifyEqual(reset.currentMovingImage, state.movingImage);
            testCase.verifyEmpty(reset.alignedImage);
            testCase.verifyEmpty(reset.maskImage);
            testCase.verifyEmpty(reset.maskPoints);
            testCase.verifyEmpty(reset.maskHistory);
        end

        function restoreSnapshotsRebuildStateFields(testCase)
            setupLabKitTestPath();

            state = baseState();
            editSnapshot = struct( ...
                'reference', uint8(1), ...
                'moving', uint8(2), ...
                'aligned', uint8(3), ...
                'cropReference', uint8(4), ...
                'cropMoving', uint8(5), ...
                'maskImage', uint8([0 255]), ...
                'maskPoints', [1 2; 3 4], ...
                'description', 'crop');
            maskSnapshot = struct( ...
                'maskImage', uint8([255 0]), ...
                'maskPoints', [5 6; 7 8], ...
                'description', 'mask');

            state = dic_preprocess.state.restoreEditSnapshot(state, editSnapshot);
            state = dic_preprocess.state.restoreMaskSnapshot(state, maskSnapshot);

            testCase.verifyEqual(state.currentReferenceImage, uint8(1));
            testCase.verifyEqual(state.currentMovingImage, uint8(2));
            testCase.verifyEqual(state.cropMoving, uint8(5));
            testCase.verifyEqual(state.maskImage, uint8([255 0]));
            testCase.verifyEqual(state.maskPoints, [5 6; 7 8]);
        end

        function applyBoundaryToMaskAddsAndSubtractsCanvas(testCase)
            setupLabKitTestPath();

            reference = zeros(3, 4, 'uint8');
            boundary = uint8([0 255 0 0; 0 255 255 0; 0 0 0 0]);
            existing = uint8([255 0 0 0; 0 255 0 0; 0 0 0 0]);

            added = dic_preprocess.state.applyBoundaryToMask([], ...
                reference, boundary, 'add');
            subtracted = dic_preprocess.state.applyBoundaryToMask(existing, ...
                reference, boundary, 'subtract');

            testCase.verifyEqual(added, boundary);
            testCase.verifyEqual(subtracted, ...
                uint8([255 0 0 0; 0 0 0 0; 0 0 0 0]));
        end
    end
end

function state = baseState()
    state = struct();
    state.currentReferenceImage = [];
    state.currentMovingImage = [];
    state.alignedImage = [];
    state.cropReference = [];
    state.cropMoving = [];
    state.maskImage = [];
    state.maskPoints = [];
    state.history = struct('reference', {}, 'moving', {}, 'aligned', {}, ...
        'cropReference', {}, 'cropMoving', {}, 'maskImage', {}, ...
        'maskPoints', {}, 'description', {});
    state.maskHistory = struct('maskImage', {}, 'maskPoints', {}, 'description', {});
    state.referencePath = "";
    state.movingPath = "";
    state.referenceImage = [];
    state.movingImage = [];
    state.cropRect = [];
end

function state = populatedState()
    state = baseState();
    state.referencePath = "reference.png";
    state.movingPath = "moving.png";
    state.referenceImage = uint8(ones(2, 3));
    state.movingImage = uint8(2 .* ones(2, 3));
    state.currentReferenceImage = uint8(3 .* ones(2, 3));
    state.currentMovingImage = uint8(4 .* ones(2, 3));
    state.alignedImage = uint8(5 .* ones(2, 3));
    state.cropReference = uint8(6 .* ones(1, 2));
    state.cropMoving = uint8(7 .* ones(1, 2));
    state.cropRect = [1 1 2 2];
    state.maskImage = uint8([0 255]);
    state.maskPoints = [1 2; 3 4; 5 6];
    state.maskHistory = struct( ...
        'maskImage', {uint8(1)}, ...
        'maskPoints', {[1 2]}, ...
        'description', {'mask'});
    state.history = struct( ...
        'reference', {uint8(1)}, ...
        'moving', {uint8(2)}, ...
        'aligned', {uint8(3)}, ...
        'cropReference', {uint8(4)}, ...
        'cropMoving', {uint8(5)}, ...
        'maskImage', {uint8(6)}, ...
        'maskPoints', {[1 2]}, ...
        'description', {'edit'});
end
