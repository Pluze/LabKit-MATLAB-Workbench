% Expected caller: DIC preprocess runner. Output is the app state struct with
% default image, crop, mask, and undo-history fields. Side effects: none.

function S = initialState()
%INITIALSTATE Build the default DIC preprocess app state.

    S = struct();
    S.referencePath = "";
    S.movingPath = "";
    S.referenceImage = [];
    S.movingImage = [];
    S.currentReferenceImage = [];
    S.currentMovingImage = [];
    S.alignedImage = [];
    S.cropReference = [];
    S.cropMoving = [];
    S.cropRect = [];
    S.cropRoiTop = [];
    S.cropRoiBottom = [];
    S.cropRoiListeners = {};
    S.maskImage = [];
    S.maskPoints = [];
    S.maskEditor = [];
    S.maskBoundaryStyle = "Curve";
    S.maskEditActive = false;
    S.maskHistory = struct('maskImage', {}, 'maskPoints', {}, 'description', {});
    S.history = struct('reference', {}, 'moving', {}, 'aligned', {}, ...
        'cropReference', {}, 'cropMoving', {}, 'maskImage', {}, ...
        'maskPoints', {}, 'description', {});
end
