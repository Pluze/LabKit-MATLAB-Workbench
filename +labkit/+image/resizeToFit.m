function [imageOut, scale] = resizeToFit(imageIn, varargin)
%RESIZETOFIT Resize an image to fit within maximum row/column limits.
%
% App-facing contract:
%   imageOut = labkit.image.resizeToFit(imageIn, "MaxHeight", 1500)
%   [imageOut, scale] = labkit.image.resizeToFit(...)
%
% Inputs:
%   imageIn - numeric image data.
%   MaxHeight - optional positive scalar, default Inf.
%   MaxWidth - optional positive scalar, default Inf.
%   AllowUpscale - optional logical scalar, default false.
%   Method - optional resize method text, default "bilinear".
%
% Outputs:
%   imageOut - resized image data. If the image already fits and upscaling is
%       disabled, the input is returned unchanged.
%   scale - scalar applied to both rows and columns.

    opts = parseOptions(varargin{:});
    imageOut = imageIn;
    scale = 1;
    if isempty(imageIn)
        return;
    end

    rows = size(imageIn, 1);
    cols = size(imageIn, 2);
    heightScale = double(opts.MaxHeight) ./ double(rows);
    widthScale = double(opts.MaxWidth) ./ double(cols);
    scale = min([heightScale, widthScale, 1]);
    if opts.AllowUpscale
        scale = min(heightScale, widthScale);
    end
    if ~isfinite(scale) || scale <= 0
        scale = 1;
    end
    if abs(scale - 1) < eps
        return;
    end

    targetSize = max(1, round([rows, cols] .* scale));
    imageOut = resizeImage(imageIn, targetSize, opts.Method);
end

function imageOut = resizeImage(imageIn, targetSize, method)
    method = lower(string(method));
    if method == "nearest"
        imageOut = resizeNearest(imageIn, targetSize);
    else
        imageOut = resizeLinear(imageIn, targetSize);
    end
end

function imageOut = resizeNearest(imageIn, targetSize)
    targetRows = max(1, round(targetSize(1)));
    targetCols = max(1, round(targetSize(2)));
    rowIdx = nearestIndices(size(imageIn, 1), targetRows);
    colIdx = nearestIndices(size(imageIn, 2), targetCols);
    imageOut = imageIn(rowIdx, colIdx, :);
end

function imageOut = resizeLinear(imageIn, targetSize)
    targetRows = max(1, round(targetSize(1)));
    targetCols = max(1, round(targetSize(2)));
    if isempty(imageIn)
        imageOut = zeros([targetRows targetCols size(imageIn, 3)], 'like', imageIn);
        return;
    end
    queryRows = scaledPositions(size(imageIn, 1), targetRows);
    queryCols = scaledPositions(size(imageIn, 2), targetCols);
    [colGrid, rowGrid] = meshgrid(queryCols, queryRows);
    imageOut = zeros([targetRows targetCols size(imageIn, 3)]);
    for channel = 1:size(imageIn, 3)
        imageOut(:, :, channel) = interp2( ...
            1:size(imageIn, 2), 1:size(imageIn, 1), ...
            double(imageIn(:, :, channel)), colGrid, rowGrid, ...
            'linear', NaN);
    end
    if ndims(imageIn) <= 2
        imageOut = imageOut(:, :, 1);
    end
    imageOut = castResizeOutput(imageOut, imageIn);
end

function imageOut = castResizeOutput(imageOut, imageIn)
    if isfloat(imageIn)
        imageOut = cast(imageOut, class(imageIn));
        return;
    end
    limits = classLimits(imageIn);
    imageOut = min(max(imageOut, limits(1)), limits(2));
    imageOut = cast(round(imageOut), class(imageIn));
end

function limits = classLimits(imageIn)
    if isa(imageIn, 'uint8')
        limits = [0 double(intmax('uint8'))];
    elseif isa(imageIn, 'uint16')
        limits = [0 double(intmax('uint16'))];
    elseif isa(imageIn, 'int16')
        limits = [double(intmin('int16')) double(intmax('int16'))];
    else
        values = double(imageIn(:));
        limits = [min(values) max(values)];
    end
end

function idx = nearestIndices(inputLength, outputLength)
    if outputLength <= 1
        idx = 1;
        return;
    end
    positions = linspace(1, inputLength, outputLength);
    idx = min(max(round(positions), 1), inputLength);
end

function positions = scaledPositions(inputLength, outputLength)
    if outputLength <= 1
        positions = 1;
    else
        positions = linspace(1, inputLength, outputLength);
    end
end

function opts = parseOptions(varargin)
    p = inputParser;
    p.FunctionName = "labkit.image.resizeToFit";
    p.addParameter("MaxHeight", inf, @isPositiveScalar);
    p.addParameter("MaxWidth", inf, @isPositiveScalar);
    p.addParameter("AllowUpscale", false, @isLogicalScalar);
    p.addParameter("Method", "bilinear", @isTextScalar);
    p.parse(varargin{:});
    opts = p.Results;
    opts.MaxHeight = double(opts.MaxHeight);
    opts.MaxWidth = double(opts.MaxWidth);
    opts.AllowUpscale = logical(opts.AllowUpscale);
    opts.Method = string(opts.Method);
end

function tf = isPositiveScalar(value)
    tf = isnumeric(value) && isscalar(value) && value > 0;
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end
