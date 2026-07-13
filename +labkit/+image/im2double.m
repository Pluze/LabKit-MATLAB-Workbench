function imageOut = im2double(imageIn, imageType)
%IM2DOUBLE Convert image data to double using MATLAB's im2double contract.
%
% App-facing contract:
%   imageOut = labkit.image.im2double(imageIn)
%   imageOut = labkit.image.im2double(indexedImage, "indexed")
%
% Inputs:
%   imageIn - logical, uint8, uint16, int16, single, or double image data.
%   imageType - optional "indexed" flag. For uint8 and uint16 indexed data,
%       one is added after conversion to preserve MATLAB's one-based double
%       colormap indices.
%
% Outputs:
%   imageOut - double image data with the same class scaling and indexed-image
%       offset as MATLAB im2double. Empty input returns an empty double array.

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
