% App-owned image rotation helper. Expected caller: cropImage. Inputs are
% image data, angle in degrees, and fill value. Output is a loose rotated
% canvas with background filled consistently for grayscale/RGB images.
function [canvas, mask, info] = rotateCanvas(imageData, angleDeg, fillValue)
%ROTATEIMAGECANVAS Rotate an image without resizing its pixel scale.
% Expected caller: cropImage. The output canvas may be larger than the
% input when angleDeg is nonzero. The implementation uses base MATLAB
% interpolation so CI does not require Image Processing Toolbox.

    if nargin < 3
        fillValue = 0;
    end

    % Constant: this degree tolerance absorbs floating-point roundoff when
    % users enter rotations equivalent to a full turn.
    identityAngleToleranceDeg = 1e-12;
    if abs(mod(double(angleDeg), 360)) < identityAngleToleranceDeg
        canvas = imageData;
        mask = true(size(imageData, 1), size(imageData, 2));
        info = struct( ...
            'identity', true, ...
            'angleDeg', double(angleDeg), ...
            'centerX', (size(imageData, 2) + 1) / 2, ...
            'centerY', (size(imageData, 1) + 1) / 2, ...
            'minX', 0, ...
            'minY', 0);
        return;
    end

    [xInput, yInput, mask, info] = looseRotationGrid(size(imageData, 1), ...
        size(imageData, 2), angleDeg);
    canvas = interpolateImage(imageData, xInput, yInput, mask, fillValue);
end

function [xInput, yInput, mask, info] = looseRotationGrid(height, width, angleDeg)
    cx = (width + 1) / 2;
    cy = (height + 1) / 2;
    theta = deg2rad(double(angleDeg));
    c = cos(theta);
    s = sin(theta);

    corners = [1, width, width, 1; 1, 1, height, height];
    centeredCorners = corners - [cx; cy];
    rotatedCorners = [c, -s; s, c] * centeredCorners;
    minX = floor(min(rotatedCorners(1, :)));
    maxX = ceil(max(rotatedCorners(1, :)));
    minY = floor(min(rotatedCorners(2, :)));
    maxY = ceil(max(rotatedCorners(2, :)));

    [xRot, yRot] = meshgrid(minX:maxX, minY:maxY);
    xCentered = c .* xRot + s .* yRot;
    yCentered = -s .* xRot + c .* yRot;
    xInput = xCentered + cx;
    yInput = yCentered + cy;
    mask = xInput >= 1 & xInput <= width & yInput >= 1 & yInput <= height;
    info = struct( ...
        'identity', false, ...
        'angleDeg', double(angleDeg), ...
        'centerX', cx, ...
        'centerY', cy, ...
        'minX', minX, ...
        'minY', minY);
end

function canvas = interpolateImage(imageData, xInput, yInput, mask, fillValue)
    outHeight = size(xInput, 1);
    outWidth = size(xInput, 2);
    if ismatrix(imageData)
        canvas = interpolatePlane(imageData, xInput, yInput, mask, fillValue);
    else
        canvas = repmat(castFillValue(fillValue, imageData), ...
            outHeight, outWidth, size(imageData, 3));
        for channel = 1:size(imageData, 3)
            canvas(:, :, channel) = interpolatePlane(imageData(:, :, channel), ...
                xInput, yInput, mask, fillValue);
        end
    end
end

function plane = interpolatePlane(inputPlane, xInput, yInput, mask, fillValue)
    interpolated = interp2(double(inputPlane), xInput, yInput, 'linear', NaN);
    interpolated(~mask | isnan(interpolated)) = double(fillValue);

    if islogical(inputPlane)
        plane = interpolated >= 0.5;
    elseif isinteger(inputPlane)
        className = class(inputPlane);
        minValue = double(intmin(className));
        maxValue = double(intmax(className));
        interpolated = min(max(round(interpolated), minValue), maxValue);
        plane = cast(interpolated, className);
    else
        plane = cast(interpolated, class(inputPlane));
    end
end

function value = castFillValue(fillValue, imageData)
    if islogical(imageData)
        value = logical(fillValue);
    else
        value = cast(fillValue, class(imageData));
    end
end
