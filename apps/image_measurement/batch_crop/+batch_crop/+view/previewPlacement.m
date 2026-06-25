% Expected caller: batch_crop.run preview drawing and view-capture paths.
% Input is one crop-canvas geometry struct. Output is display placement data
% used to align padded canvas coordinates to source-image coordinates.
function placement = previewPlacement(geometry)
%PREVIEWPLACEMENT Compute preview x/y data and canvas offset.

    sourceCenter = batch_crop.ops.sourceCenterFromSize( ...
        geometry.sourceWidth, geometry.sourceHeight);
    canvasCenter = batch_crop.ops.originalToCanvas(geometry, sourceCenter);
    offset = sourceCenter - canvasCenter;
    placement = struct( ...
        'offset', offset, ...
        'xData', [1, size(geometry.canvas, 2)] + offset(1), ...
        'yData', [1, size(geometry.canvas, 1)] + offset(2));
end
