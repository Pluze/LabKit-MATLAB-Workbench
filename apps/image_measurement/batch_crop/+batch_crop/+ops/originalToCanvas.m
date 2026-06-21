% App-owned coordinate transform helper. Expected caller: batch-crop preview
% rendering, cropImage, and tests. Inputs are a prepareCropCanvas geometry
% struct and one original-image [x y] point. Output is the corresponding
% rotated canvas [x y] point.
function canvasXY = originalToCanvas(geometry, originalXY)
%ORIGINALTOCANVAS Map unpadded source-image coordinates to preview canvas coordinates.

    point = double(originalXY(:)).';
    xPadded = point(1) + geometry.padding.left;
    yPadded = point(2) + geometry.padding.top;

    if geometry.rotation.identity
        canvasXY = [xPadded, yPadded];
        return;
    end

    theta = deg2rad(double(geometry.rotation.angleDeg));
    c = cos(theta);
    s = sin(theta);
    dx = xPadded - geometry.rotation.centerX;
    dy = yPadded - geometry.rotation.centerY;
    xCentered = c .* dx - s .* dy;
    yCentered = s .* dx + c .* dy;
    canvasXY = [xCentered - geometry.rotation.minX + 1, ...
        yCentered - geometry.rotation.minY + 1];
end
