function processed = applyPipeline(images, steps, contexts)
%APPLYPIPELINE Replay an ordered non-destructive image enhancement history.
%
% Usage:
%   processed = image_enhance.analysisRun.applyPipeline(images, steps)
%   processed = image_enhance.analysisRun.applyPipeline(images, steps, contexts)
%
% Description:
%   Converts every input image to RGB double data, then applies each history
%   step in order. The same step sequence is applied independently to every
%   image. The input arrays and step records are not modified, so the function
%   can be used outside the GUI for reproducible preview or export processing.
%
% Inputs:
%   images - One numeric image or a cell array of numeric images. Grayscale and
%       multichannel inputs are converted to M-by-N-by-3 RGB double images and
%       limited to [0,1]. The returned cell order matches the input order.
%   steps - Structure array created by image_enhance.analysisRun.makeStep.
%       Steps are reshaped to a column and executed in array order. An empty
%       array performs normalization only.
%   contexts - Optional cell array with one entry per image. Context is used by
%       "White ROI calibration" to find whiteRoi, either directly as
%       context.whiteRoi or as context.item.whiteRoi. Other step kinds ignore
%       it. Default: one empty context per image.
%
% Step Fields:
%   kind - One label returned by image_enhance.userInterface.toolKinds:
%       "Brightness/contrast", "Local contrast", "Sharpen",
%       "Hue/saturation", "White balance", "White ROI calibration", or
%       "Subject-preserving enhance".
%   amount - Primary numeric control. It is brightness percentage, local-
%       contrast strength, sharpening strength, hue rotation in degrees,
%       white-balance strength, or protected-enhancement blend strength,
%       depending on kind.
%   secondary - Secondary numeric control. It is contrast percentage, radius
%       in pixels, saturation percentage, warm/cool percentage, or target
%       background white level in percent, depending on kind.
%   referenceIndex - Preserved history metadata; applyPipeline does not use it.
%   label - Human-readable history text; applyPipeline does not branch on it.
%
% Outputs:
%   processed - Column cell array of M-by-N-by-3 double images in [0,1]. Each
%       output preserves its corresponding source height and width.
%
% Errors:
%   labkit_ImageEnhance_app:UnknownEnhancementStep - A step kind is not one of
%       the supported labels.
%   labkit_ImageEnhance_app:MissingWhiteRoi - "White ROI calibration" is used
%       without a valid [x y width height] ROI in that image's context.
%   MATLAB indexing errors - A nonempty contexts array has fewer entries than
%       images.
%
% Example:
%   imageData = repmat(linspace(0.1, 0.8, 20), 12, 1);
%   steps = [ ...
%       image_enhance.analysisRun.makeStep("Brightness/contrast", 10, 20, 0); ...
%       image_enhance.analysisRun.makeStep("Sharpen", 30, 1, 0)];
%   processed = image_enhance.analysisRun.applyPipeline(imageData, steps);
%   assert(iscell(processed) && isequal(size(processed{1}), [12 20 3]))
%
% See also image_enhance.analysisRun.applyStep,
%   image_enhance.analysisRun.makeStep, labkit.image.adjustBrightnessContrast

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
