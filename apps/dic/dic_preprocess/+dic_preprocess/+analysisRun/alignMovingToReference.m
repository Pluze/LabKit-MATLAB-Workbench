% Expected caller: DIC preprocess runner. Inputs are the current
% reference/moving images and matched fixed/moving control points. Outputs are
% the rigidly aligned moving image and 3x3 transform matrix. Side effects: none.

function [alignedImage, tformRigid] = alignMovingToReference(referenceImage, movingImage, fixedPoints, movingPoints)
%ALIGNMOVINGTOREFERENCE Rigidly align the moving image to the reference image.

    origClass = class(movingImage);
    [R, t] = rigidTransformFromPoints(fixedPoints, movingPoints);
    T = [R(1,1) R(1,2) 0; ...
         R(2,1) R(2,2) 0; ...
         t(1)   t(2)   1];
    tformRigid = T;

    alignedImage = warpRigid(movingImage, R, t, size(referenceImage(:, :, 1)));
    alignedImage = cast(alignedImage, origClass);
end

function [R, t] = rigidTransformFromPoints(fixedPoints, movingPoints)
    fixedPoints = double(fixedPoints);
    movingPoints = double(movingPoints);
    fixedCenter = mean(fixedPoints, 1);
    movingCenter = mean(movingPoints, 1);
    fixedCentered = fixedPoints - fixedCenter;
    movingCentered = movingPoints - movingCenter;
    H = movingCentered.' * fixedCentered;
    [U, ~, V] = svd(H);
    R = V * U.';
    if det(R) < 0
        V(:, end) = -V(:, end);
        R = V * U.';
    end
    t = fixedCenter - movingCenter * R;
end

function imageOut = warpRigid(imageIn, R, t, outputSize)
    rows = outputSize(1);
    cols = outputSize(2);
    imageOut = zeros([rows, cols, size(imageIn, 3)], 'like', imageIn);
    [xGrid, yGrid] = meshgrid(1:cols, 1:rows);
    source = ([xGrid(:), yGrid(:)] - t) * R.';
    sourceX = reshape(source(:, 1), rows, cols);
    sourceY = reshape(source(:, 2), rows, cols);
    valid = sourceX >= 1 & sourceX <= size(imageIn, 2) & ...
        sourceY >= 1 & sourceY <= size(imageIn, 1);
    for channel = 1:size(imageIn, 3)
        sampled = interp2( ...
            1:size(imageIn, 2), 1:size(imageIn, 1), ...
            double(imageIn(:, :, channel)), sourceX, sourceY, ...
            'linear', 0);
        sampled(~valid) = 0;
        imageOut(:, :, channel) = castToInputClass(sampled, imageIn);
    end
    if ndims(imageIn) <= 2
        imageOut = imageOut(:, :, 1);
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
