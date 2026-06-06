% Expected caller: DIC preprocess runner and direct unit tests. Input is a state
% with loaded original images. Output restores the current pair to originals and
% clears operation-derived outputs. Side effects: none.

function S = resetToOriginals(S)
%RESETTOORIGINALS Restore the DIC preprocess current pair to loaded originals.

    S.currentReferenceImage = S.referenceImage;
    S.currentMovingImage = S.movingImage;
    S.alignedImage = [];
    S.cropReference = [];
    S.cropMoving = [];
    S.cropRect = [];
    S = dic_preprocess.state.clearOperationDerivedState(S);
end
