function alignedImage = applyRigidTransform(referenceImage, movingImage, transform)
%APPLYRIGIDTRANSFORM Resample a moving image onto a reference-sized canvas.
%
% Usage:
%   alignedImage = dic_preprocess.analysisRun.applyRigidTransform( ...
%       referenceImage, movingImage, transform)
%
% Inputs:
%   referenceImage - Image whose height and width define the output canvas.
%       Its pixel values and channel count are not used.
%   movingImage - Numeric two-dimensional or multichannel source image.
%   transform - Three-by-three row-vector homogeneous rigid transform. Source
%       points map forward as [x y 1]*transform. The upper-left two-by-two block
%       is rotation and row 3, columns 1:2 are [x y] translation.
%
% Outputs:
%   alignedImage - Linearly interpolated moving image on the reference height
%       and width, preserving movingImage class and channels. Samples outside
%       movingImage are 0; integer outputs are rounded and clipped to range.
%
% Description:
%   The function performs inverse mapping for every output pixel using base
%   MATLAB interp2. It assumes the supplied two-by-two block is an orthogonal
%   rotation; scale or shear matrices are not validated.
%
% Example:
%   moving = uint8(reshape(1:25, 5, 5));
%   transform = [1 0 0; 0 1 0; 1 0 1];
%   aligned = dic_preprocess.analysisRun.applyRigidTransform( ...
%       zeros(5), moving, transform);
%   assert(isa(aligned, "uint8") && aligned(1,1) == 0)
%   assert(aligned(1,2) == moving(1,1))
%
% See also dic_preprocess.analysisRun.alignMovingToReference
    transform = double(transform);
    R = transform(1:2, 1:2);
    translation = transform(3, 1:2);
    rows = size(referenceImage, 1);
    cols = size(referenceImage, 2);
    [xGrid, yGrid] = meshgrid(1:cols, 1:rows);
    source = ([xGrid(:), yGrid(:)] - translation) * R.';
    sourceX = reshape(source(:, 1), rows, cols);
    sourceY = reshape(source(:, 2), rows, cols);
    valid = sourceX >= 1 & sourceX <= size(movingImage, 2) & ...
        sourceY >= 1 & sourceY <= size(movingImage, 1);
    alignedImage = zeros([rows, cols, size(movingImage, 3)], 'like', movingImage);
    for channel = 1:size(movingImage, 3)
        sampled = interp2( ...
            1:size(movingImage, 2), 1:size(movingImage, 1), ...
            double(movingImage(:, :, channel)), sourceX, sourceY, ...
            'linear', 0);
        sampled(~valid) = 0;
        alignedImage(:, :, channel) = castToInputClass(sampled, movingImage);
    end
    if ndims(movingImage) <= 2
        alignedImage = alignedImage(:, :, 1);
    end
end

function imageOut = castToInputClass(imageData, imageIn)
    if isfloat(imageIn)
        imageOut = cast(imageData, class(imageIn));
    elseif isa(imageIn, 'uint8')
        imageOut = uint8(round(min(max(imageData, 0), double(intmax('uint8')))));
    elseif isa(imageIn, 'uint16')
        imageOut = uint16(round(min(max(imageData, 0), double(intmax('uint16')))));
    elseif isa(imageIn, 'int16')
        imageOut = int16(round(min(max(imageData, double(intmin('int16'))), ...
            double(intmax('int16')))));
    else
        imageOut = cast(round(imageData), class(imageIn));
    end
end
