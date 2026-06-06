% Expected caller: DIC preprocess runner and direct unit tests. Input is the app
% state after a new image path/image was assigned. Output resets current images
% and derived edit state while preserving loaded originals. Side effects: none.

function S = resetForNewInput(S)
%RESETFORNEWINPUT Reset derived DIC preprocess state for a newly loaded image.

    if ~isempty(S.referenceImage)
        S.currentReferenceImage = S.referenceImage;
    end
    if ~isempty(S.movingImage)
        S.currentMovingImage = S.movingImage;
    end
    S.alignedImage = [];
    S.cropReference = [];
    S.cropMoving = [];
    S.cropRect = [];
    S = dic_preprocess.state.clearOperationDerivedState(S);
    S.history = S.history([]);
end
