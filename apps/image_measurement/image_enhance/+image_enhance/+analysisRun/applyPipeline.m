% Expected caller: labkit_ImageEnhance_app, batch export, and tests. Inputs are
% source RGB double images in a cell array and an ordered step array. Output is
% a cell array after applying the same non-destructive history pipeline to each
% image.
function processed = applyPipeline(images, steps, contexts)

    images = normalizeImages(images);
    steps = steps(:);
    processed = images;
    if nargin < 3 || isempty(contexts)
        contexts = repmat({[]}, numel(images), 1);
    end

    for iStep = 1:numel(steps)
        step = steps(iStep);
        for iImage = 1:numel(processed)
            processed{iImage} = image_enhance.analysisRun.applyStep( ...
                processed{iImage}, step, contexts{iImage});
        end
    end
end

function images = normalizeImages(images)
    if isnumeric(images)
        images = {images};
    end
    images = images(:);
    for k = 1:numel(images)
        images{k} = labkit.image.ensureRgb(labkit.image.im2double(images{k}));
        images{k} = min(max(images{k}, 0), 1);
    end
end
