% App-owned overlay geometry helper. Expected caller: batch-crop app preview
% rendering. Inputs are center and crop size in pixels. Output is a MATLAB
% rectangle Position vector and has no side effects.
function position = rectanglePosition(centerXY, cropWidth, cropHeight)
%RECTANGLEPOSITION Return rectangle overlay position for a crop box.

    colStart = round(centerXY(1) - (cropWidth - 1) / 2);
    rowStart = round(centerXY(2) - (cropHeight - 1) / 2);
    position = [colStart - 0.5, rowStart - 0.5, cropWidth, cropHeight];
end
