% App-owned coordinate transform helper. Expected caller: batch-crop pointer
% callbacks and tests. Inputs are a prepareCropCanvas geometry struct and one
% preview canvas [x y] point. Output is the corresponding unpadded source-image
% [x y] point.
function originalXY = canvasToOriginal(geometry, canvasXY)
%CANVASTOORIGINAL Map preview canvas coordinates back to source-image coordinates.

    point = double(canvasXY(:)).';
    if geometry.rotation.identity
        originalXY = previewSourceToOriginal(geometry, ...
            [point(1) - geometry.padding.left, ...
            point(2) - geometry.padding.top]);
        return;
    end

    theta = deg2rad(double(geometry.rotation.angleDeg));
    c = cos(theta);
    s = sin(theta);
    xCentered = point(1) + geometry.rotation.minX - 1;
    yCentered = point(2) + geometry.rotation.minY - 1;
    xPadded = c .* xCentered + s .* yCentered + geometry.rotation.centerX;
    yPadded = -s .* xCentered + c .* yCentered + geometry.rotation.centerY;
    originalXY = previewSourceToOriginal(geometry, ...
        [xPadded - geometry.padding.left, ...
        yPadded - geometry.padding.top]);
end

function point = previewSourceToOriginal(geometry, point)
    scale = batch_crop.cropGeometry.geometryScale(geometry);
    point = (point - 0.5) ./ scale + 0.5;
end
