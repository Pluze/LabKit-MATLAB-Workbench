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
    imageOut = imresize(imageIn, targetSize, char(opts.Method));
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
