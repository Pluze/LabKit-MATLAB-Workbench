% Expected caller: labkit_ImageMatch_app, batch export, and tests. Inputs are
% RGB images in a cell array and an ordered reference-match step array. Output
% is a cell array after applying each match step; references are processed up to
% the previous step for deterministic batch matching.
function processed = applyPipeline(images, steps)

    images = normalizeImages(images);
    steps = steps(:);
    processed = images;

    for iStep = 1:numel(steps)
        step = steps(iStep);
        referenceIndex = min(max(1, round(step.referenceIndex)), numel(processed));
        referenceImage = processed{referenceIndex};
        for iImage = 1:numel(processed)
            processed{iImage} = image_match.ops.applyStep( ...
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
        images{k} = min(max(im2double(images{k}), 0), 1);
        if ndims(images{k}) == 2
            images{k} = repmat(images{k}, 1, 1, 3);
        end
    end
end
