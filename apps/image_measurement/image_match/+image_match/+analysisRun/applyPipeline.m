% Expected caller: labkit_ImageMatch_app, batch export, and tests. Inputs are
% source RGB images, an ordered reference-match step array, and one immutable
% reference RGB image. Output is a cell array after applying each match step to
% source images only; the reference image is never modified or exported.
function processed = applyPipeline(images, steps, referenceImage)

    images = normalizeImages(images);
    if nargin < 3
        referenceImage = [];
    end
    referenceImage = normalizeImage(referenceImage);
    steps = steps(:);
    processed = images;

    for iStep = 1:numel(steps)
        step = steps(iStep);
        for iImage = 1:numel(processed)
            processed{iImage} = image_match.analysisRun.applyStep( ...
                processed{iImage}, step, referenceImage);
        end
    end
end

function images = normalizeImages(images)
    if isnumeric(images)
        images = {images};
    end
    images = images(:);
    for k = 1:numel(images)
        images{k} = normalizeImage(images{k});
    end
end

function imageData = normalizeImage(imageData)
    if isempty(imageData)
        return;
    end
    imageData = labkit.image.toRgbDouble(imageData);
end
