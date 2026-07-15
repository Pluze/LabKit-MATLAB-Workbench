% Expected callers: DIC alignment and durable edit-step replay. Inputs are a
% reference image, moving image, and row-vector 3x3 rigid transform. Output is
% the moving image warped onto the reference canvas using base MATLAB.
function alignedImage = applyRigidTransform(referenceImage, movingImage, transform)
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
