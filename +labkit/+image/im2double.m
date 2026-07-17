function imageOut = im2double(imageIn, imageType)
%IM2DOUBLE Convert image data to double using MATLAB's im2double contract.
%
% Usage:
%   imageOut = labkit.image.im2double(imageIn)
%   imageOut = labkit.image.im2double(indexedImage, "indexed")
%
% Description:
%   Converts image data to double without requiring Image Processing Toolbox.
%   Logical values become 0 or 1. uint8 and uint16 values are divided by the
%   maximum value of their class. int16 values are mapped linearly from the
%   complete signed range to [0,1]. single and double values are converted to
%   double without rescaling or clipping.
%
%   For uint8 or uint16 indexed images, the "indexed" form converts the
%   zero-based integer storage to one-based double colormap indices. For
%   example, uint8 values [0 1] become [1 2]. Empty input returns an empty
%   double array.
%
% Inputs:
%   imageIn - Logical, uint8, uint16, int16, single, or double image array.
%   imageType - Optional character vector or scalar string "indexed". No
%               other image-type value is accepted.
%
% Outputs:
%   imageOut - Double array with the same size as imageIn.
%
% Errors:
%   labkit:image:im2double:InvalidImageType - imageType is not "indexed".
%   labkit:image:im2double:UnsupportedClass - imageIn has an unsupported
%                                            numeric class.
%
% Example:
%   intensity = labkit.image.im2double(uint8([0 128 255]));
%   indices = labkit.image.im2double(uint8([0 1 2]), "indexed");
%
% See also labkit.image.ensureRgb,
%   labkit.image.rgb2gray

    narginchk(1, 2);
    indexed = false;
    if nargin == 2
        indexed = strcmpi(string(imageType), "indexed");
        if ~isscalar(indexed) || ~indexed
            error('labkit:image:im2double:InvalidImageType', ...
                'The optional image type must be "indexed".');
        end
    end

    if isa(imageIn, 'double')
        imageOut = imageIn;
    elseif islogical(imageIn) || isfloat(imageIn)
        imageOut = double(imageIn);
    elseif isa(imageIn, 'uint8')
        imageOut = double(imageIn) ./ double(intmax('uint8'));
    elseif isa(imageIn, 'uint16')
        imageOut = double(imageIn) ./ double(intmax('uint16'));
    elseif isa(imageIn, 'int16')
        imageOut = (double(imageIn) - double(intmin('int16'))) ./ ...
            (double(intmax('int16')) - double(intmin('int16')));
    else
        error('labkit:image:im2double:UnsupportedClass', ...
            'Unsupported image class: %s.', class(imageIn));
    end

    if indexed && (isa(imageIn, 'uint8') || isa(imageIn, 'uint16'))
        imageOut = imageOut .* double(intmax(class(imageIn))) + 1;
    end
end
