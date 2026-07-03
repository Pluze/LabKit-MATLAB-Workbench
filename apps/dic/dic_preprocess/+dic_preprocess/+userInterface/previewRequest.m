% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% runner state and preview dropdown value. Output is a struct containing the
% top/bottom preview images and titles to render. Side effects: none.

function request = previewRequest(S, previewValue)
%PREVIEWREQUEST Prepare DIC preprocess preview images for the selected mode.

    previewValue = string(previewValue);
    request = struct( ...
        'topImage', [], ...
        'topTitle', "", ...
        'bottomImage', [], ...
        'bottomTitle', "");

    switch previewValue
        case "Current pair"
            request.topImage = S.currentReferenceImage;
            request.topTitle = "Current reference";
            request.bottomImage = S.currentMovingImage;
            request.bottomTitle = "Current moving";
        case "Original pair"
            request.topImage = S.referenceImage;
            request.topTitle = "Original reference";
            request.bottomImage = S.movingImage;
            request.bottomTitle = "Original moving";
        case "ROI mask"
            request.topImage = S.currentReferenceImage;
            request.topTitle = "Current reference";
            if ~isempty(S.maskImage)
                request.bottomImage = dic_preprocess.analysisRun.maskRgb(S.maskImage);
                request.bottomTitle = "ROI mask";
            end
        otherwise
            request.topImage = S.currentReferenceImage;
            request.topTitle = "Current reference";
            if previewValue == "Current moving image"
                request.bottomImage = S.currentMovingImage;
                request.bottomTitle = previewValue;
            elseif previewValue == "False-color overlay" && hasImagePair(S)
                request.bottomImage = dic_preprocess.analysisRun.makeFalseColorOverlay( ...
                    S.currentReferenceImage, S.currentMovingImage);
                request.bottomTitle = previewValue;
            end
    end
end

function tf = hasImagePair(S)
    tf = ~isempty(S.currentReferenceImage) && ~isempty(S.currentMovingImage);
end
