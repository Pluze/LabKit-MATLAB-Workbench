function processed = applyPipeline(images, steps, referenceImage)
%APPLYPIPELINE Replay ordered reference-match steps over source images.
%
% Usage:
%   processed = image_match.analysisRun.applyPipeline(images, steps)
%   processed = image_match.analysisRun.applyPipeline( ...
%       images, steps, referenceImage)
%
% Description:
%   Normalizes each source image and applies the ordered reference-match history
%   independently to every source. A step sees the output of the preceding
%   step. The reference image is normalized once, remains separate from the
%   source batch, and is never included in the returned cell array.
%
% Inputs:
%   images - One numeric image or a cell array of source images. Each source is
%       converted to RGB double data in [0,1]. Cell order is preserved.
%   steps - Structure array created by image_match.analysisRun.makeStep. Steps
%       are reshaped to a column and executed in array order. An empty array
%       performs source normalization only.
%   referenceImage - Optional numeric reference image. Its dimensions may differ
%       from the sources. Empty or omitted input makes every match step a no-op
%       after source normalization. Default: [].
%
% Step Fields:
%   kind - History category; makeStep sets it to "Reference match".
%   matchMethod - "Balanced", "White balance", "Tone only", "Protected
%       tone", "Lab style", or "Histogram".
%   amount - Overall match blend percentage.
%   secondary - Tone-match percentage.
%   colorStrength - Color-match percentage.
%   label - Display text retained for history and export; it does not control
%       the calculation.
%
% Outputs:
%   processed - Column cell array containing only processed source images. Each
%       entry is an M-by-N-by-3 double image in [0,1] and keeps its own source
%       height and width.
%
% Failure Behavior:
%   Empty images returns an empty cell column; empty steps or referenceImage
%   performs normalization only. An invalid image container, unsupported image
%   value, or malformed step propagates the originating normalization or
%   applyMatch error and no partial output is returned.
%
% Example:
%   sourceA = cat(3, 0.2*ones(6), 0.4*ones(6), 0.7*ones(6));
%   sourceB = 0.6*ones(4, 5);
%   reference = cat(3, 0.7*ones(8), 0.5*ones(8), 0.3*ones(8));
%   step = image_match.analysisRun.makeStep("Balanced", 75, 100, 80);
%   processed = image_match.analysisRun.applyPipeline( ...
%       {sourceA, sourceB}, step, reference);
%   assert(numel(processed) == 2 && isequal(size(processed{2}), [4 5 3]))
%
% See also image_match.analysisRun.applyMatch,
%   image_match.analysisRun.makeStep, image_match.userInterface.matchMethods

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
    imageData = labkit.image.ensureRgb(labkit.image.im2double(imageData));
    imageData = min(max(imageData, 0), 1);
end
