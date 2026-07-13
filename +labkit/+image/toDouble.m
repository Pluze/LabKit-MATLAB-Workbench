function imageOut = toDouble(imageIn)
%TODOUBLE Convert image data to double without Image Processing Toolbox.
%
% App-facing contract:
%   imageOut = labkit.image.toDouble(imageIn)
%
% Inputs:
%   imageIn - numeric or logical image data.
%
% Outputs:
%   imageOut - double image data using MATLAB im2double-compatible image
%       class scaling for uint8, uint16, int16, logical, single, and double.
%       Empty input returns [].

    if isempty(imageIn)
        imageOut = [];
    elseif isfloat(imageIn)
        imageOut = double(imageIn);
    elseif islogical(imageIn)
        imageOut = double(imageIn);
    elseif isa(imageIn, 'uint8')
        imageOut = double(imageIn) ./ double(intmax('uint8'));
    elseif isa(imageIn, 'uint16')
        imageOut = double(imageIn) ./ double(intmax('uint16'));
    elseif isa(imageIn, 'int16')
        imageOut = (double(imageIn) - double(intmin('int16'))) ./ ...
            (double(intmax('int16')) - double(intmin('int16')));
    else
        imageOut = double(imageIn);
    end
end
