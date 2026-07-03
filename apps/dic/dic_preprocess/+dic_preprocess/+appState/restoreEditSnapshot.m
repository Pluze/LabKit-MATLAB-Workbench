% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% current app state and one edit-history snapshot. Output restores image, crop,
% alignment, and mask fields captured by that snapshot. Side effects: none.

function S = restoreEditSnapshot(S, snapshot)
%RESTOREEDITSNAPSHOT Restore a DIC preprocess align/crop undo snapshot.

    S.currentReferenceImage = snapshot.reference;
    S.currentMovingImage = snapshot.moving;
    S.alignedImage = snapshot.aligned;
    S.cropReference = snapshot.cropReference;
    S.cropMoving = snapshot.cropMoving;
    S.maskImage = snapshot.maskImage;
    S.maskPoints = snapshot.maskPoints;
end
