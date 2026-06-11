% Expected caller: labkit_ImageEnhance_app, batch export, and tests. Inputs are
% source RGB double images in a cell array and an ordered step array. Output is
% a cell array after applying the same non-destructive history pipeline to each
% image.
function processed = applyPipeline(images, steps)

    images = normalizeImages(images);
    steps = steps(:);
    processed = images;

    for iStep = 1:numel(steps)
        step = steps(iStep);
        for iImage = 1:numel(processed)
            processed{iImage} = image_enhance.ops.applyStep( ...
                processed{iImage}, step, []);
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
