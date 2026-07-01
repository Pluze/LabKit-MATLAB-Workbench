function [preview, info] = previewBudget(imageData, varargin)
%PREVIEWBUDGET Downsample image data to fit a display pixel budget.
%
% App-facing contract:
%   [preview, info] = labkit.image.previewBudget(imageData, "MaxPixels", n)
%
% Inputs:
%   imageData - 2-D or 3-D image matrix. Class and channel count are preserved.
%   MaxPixels - positive scalar display-pixel budget, default 1.2e6.
%   Expansion - positive scalar estimated processing-area multiplier before
%       preview rendering, default 1. Use this when a workflow pads or expands
%       the image before display.
%
% Outputs:
%   preview - imageData sampled at an integer stride when needed.
%   info - struct with scaleFactor, coordinateScale, maxPixels,
%       estimatedPixels, sourceSize, and previewSize.
%
% Example:
%   [preview, info] = labkit.image.previewBudget(rgb, ...
%       "MaxPixels", 1.2e6, "Expansion", 25);

    opts = parseOptions(varargin);
    validateImageData(imageData);
    maxPixels = positiveScalar(opts.MaxPixels, 1.2e6);
    expansion = positiveScalar(opts.Expansion, 1);

    estimatedPixels = double(size(imageData, 1)) * ...
        double(size(imageData, 2)) * expansion;
    factor = max(1, ceil(sqrt(estimatedPixels / maxPixels)));
    preview = imageData(1:factor:end, 1:factor:end, :);
    info = struct( ...
        'scaleFactor', factor, ...
        'coordinateScale', 1 / factor, ...
        'maxPixels', maxPixels, ...
        'estimatedPixels', estimatedPixels, ...
        'sourceSize', size(imageData), ...
        'previewSize', size(preview));
end

function opts = parseOptions(args)
    opts = struct('MaxPixels', 1.2e6, 'Expansion', 1);
    if isempty(args)
        return;
    end
    if mod(numel(args), 2) ~= 0
        error('labkit:image:InvalidPreviewBudgetOptions', ...
            'previewBudget options must be name/value pairs.');
    end
    for k = 1:2:numel(args)
        name = char(string(args{k}));
        if ~isfield(opts, name)
            error('labkit:image:InvalidPreviewBudgetOption', ...
                'Unsupported previewBudget option "%s".', name);
        end
        opts.(name) = args{k + 1};
    end
end

function validateImageData(imageData)
    if isempty(imageData) || ~(isnumeric(imageData) || islogical(imageData)) || ndims(imageData) > 3
        error('labkit:image:InvalidImageData', ...
            'Image data must be a nonempty numeric or logical 2-D or 3-D image array.');
    end
end

function value = positiveScalar(value, defaultValue)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
        value = defaultValue;
        return;
    end
end
