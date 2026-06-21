% App-owned image fill helper. Expected caller: batch-crop transform and crop
% helpers. Inputs are image data and optional crop options. Output is a scalar
% white fill value compatible with the image class.
function value = whiteFillValue(imageData, opts)
%WHITEFILLVALUE Resolve the white background value for image rotation/cropping.

    if nargin >= 2 && isstruct(opts) && isfield(opts, 'fillValue') && ~isempty(opts.fillValue)
        value = double(opts.fillValue(1));
        return;
    end

    if islogical(imageData)
        value = 1;
    elseif isinteger(imageData)
        value = double(intmax(class(imageData)));
    else
        maxPixel = max(double(imageData(:)));
        if maxPixel > 1
            value = 255;
        else
            value = 1;
        end
    end
end
