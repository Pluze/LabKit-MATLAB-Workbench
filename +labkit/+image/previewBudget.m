function [preview, info] = previewBudget(imageData, varargin)
%PREVIEWBUDGET Downsample image data to fit a display pixel budget.
%
% Usage:
%   [preview, info] = labkit.image.previewBudget(imageData)
%   [preview, info] = labkit.image.previewBudget(imageData, Name, Value)
%
% Description:
%   Produces a lightweight preview by taking every Nth row and column. N is
%   the smallest integer stride whose estimated processing area does not
%   exceed MaxPixels. The estimate is source rows times source columns times
%   Expansion, so callers can reserve memory for workflows that pad, tile, or
%   otherwise enlarge an image before display.
%
%   This is sampling rather than interpolating resize. The first source pixel
%   is always retained, and image class and channel count are preserved. A
%   preview may use fewer pixels than the budget because the stride is an
%   integer.
%
% Inputs:
%   imageData - Nonempty numeric or logical 2-D or 3-D image array.
%
% Name-Value Arguments:
%   MaxPixels - Positive display-area budget. The default is 1.2e6 pixels.
%               Invalid, empty, or nonpositive values fall back to the
%               default rather than throwing an error.
%   Expansion - Positive multiplier applied only to estimatedPixels. The
%               default is 1. Invalid values fall back to 1.
%
% Outputs:
%   preview - imageData sampled with the selected integer stride.
%   info - Scalar structure describing the preview calculation.
%
% Info Fields:
%   scaleFactor - Integer row and column stride N.
%   coordinateScale - Reciprocal 1/N for mapping source distances to the
%                     sampled preview scale.
%   maxPixels - Validated display-area budget.
%   estimatedPixels - Source row-column area multiplied by Expansion.
%   sourceSize - Original size vector.
%   previewSize - Returned preview size vector.
%
% Errors:
%   labkit:image:InvalidImageData - imageData is empty, nonnumeric/nonlogical,
%   or has more than three dimensions.
%   labkit:image:InvalidPreviewBudgetOptions - Name-value arguments are not
%   paired.
%   labkit:image:InvalidPreviewBudgetOption - An option name is unsupported.
%
% Example:
%   rgb = zeros(100, 200, 3, 'uint8');
%   [preview, info] = labkit.image.previewBudget(rgb, ...
%       "MaxPixels", 5000, "Expansion", 2);
%
% See also labkit.image.resizeToFit

    opts = parseOptions(varargin);
    validateImageData(imageData);
    maxPixels = positiveScalar(opts.MaxPixels, defaultMaxPixels());
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
    opts = struct('MaxPixels', defaultMaxPixels(), 'Expansion', 1);
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

function value = defaultMaxPixels()
    % Constant: 1.2 megapixels balances interactive preview responsiveness
    % with enough spatial detail for image measurement workflows.
    value = 1.2e6;
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
