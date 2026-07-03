% Expected caller: DIC preprocess runner and direct unit tests. Inputs are a
% candidate ROI rectangle and image size. Output is a square rectangle clamped
% inside the image bounds. Side effects: none.

function rect = squareRectInsideImage(roi, imageSize)
%SQUARERECTINSIDEIMAGE Clamp a crop ROI into a square inside image bounds.

    x = roi(1);
    y = roi(2);
    w = roi(3);
    h = roi(4);
    side = round(max(w, h));
    side = max(side, 1);
    maxSide = max(1, min(imageSize(1), imageSize(2)) - 1);
    side = min(side, maxSide);

    cx = x + w / 2;
    cy = y + h / 2;
    xSq = round(cx - side / 2);
    ySq = round(cy - side / 2);

    maxX = max(1, imageSize(2) - side);
    maxY = max(1, imageSize(1) - side);
    xSq = min(max(1, xSq), maxX);
    ySq = min(max(1, ySq), maxY);
    rect = [xSq, ySq, side, side];
end
