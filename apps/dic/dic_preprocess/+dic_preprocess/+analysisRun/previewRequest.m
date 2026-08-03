% Expected caller: DIC preprocess App SDK presenter and unit tests. Inputs are the
% canonical state and preview choice. Output is prepared image data.

function request = previewRequest(state, previewValue)
%PREVIEWREQUEST Prepare DIC preprocess preview images for the selected mode.

    cache = state.session.cache;
    annotations = state.project.annotations;
    previewValue = string(previewValue);
    request = struct( ...
        'topImage', [], ...
        'topTitle', "", ...
        'bottomImage', [], ...
        'bottomTitle', "");

    switch previewValue
        case "Current pair"
            request.topImage = cache.currentReferenceImage;
            request.topTitle = "Current reference";
            request.bottomImage = cache.currentMovingImage;
            request.bottomTitle = "Current moving";
        case "Original pair"
            request.topImage = cache.referenceImage;
            request.topTitle = "Original reference";
            request.bottomImage = cache.movingImage;
            request.bottomTitle = "Original moving";
        case "ROI mask"
            request.topImage = cache.currentReferenceImage;
            request.topTitle = "Current reference";
            if ~isempty(annotations.maskImage)
                request.bottomImage = ...
                    dic_preprocess.analysisRun.maskRgb(annotations.maskImage);
                request.bottomTitle = "ROI mask";
            end
        otherwise
            request.topImage = cache.currentReferenceImage;
            request.topTitle = "Current reference";
            if previewValue == "False-color overlay" && ...
                    dic_preprocess.sourceFiles.hasImagePair(cache)
                request.bottomImage = dic_preprocess.analysisRun.makeFalseColorOverlay( ...
                    cache.currentReferenceImage, cache.currentMovingImage);
                request.bottomTitle = previewValue;
            end
    end
end
