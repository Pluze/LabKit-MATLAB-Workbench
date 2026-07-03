% Expected caller: DIC preprocess runner and direct unit tests. Inputs are app
% state, image role, selected path, and image data. Output is the updated state
% with the selected original/current image fields assigned. Side effects: none.

function S = setLoadedImage(S, role, filepath, imageData)
%SETLOADEDIMAGE Assign a loaded reference or moving image into app state.

    if strcmp(string(role), "reference")
        S.referencePath = filepath;
        S.referenceImage = imageData;
        S.currentReferenceImage = imageData;
    else
        S.movingPath = filepath;
        S.movingImage = imageData;
        S.currentMovingImage = imageData;
    end
end
