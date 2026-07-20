% Expected caller: batch crop UI preview drawing and view-capture paths.
% Input is one crop-canvas geometry struct. Output is display placement data
% used to align padded canvas coordinates to source-image coordinates.
function placement = placement(geometry)
%PREVIEWPLACEMENT Compute preview x/y data and canvas offset.

    sourceCenter = batch_crop.cropGeometry.sourceCenterFromSize( ...
        geometry.sourceWidth, geometry.sourceHeight);
    canvasCenter = batch_crop.cropGeometry.originalToCanvas(geometry, sourceCenter);
    displayCenter = originalToPreviewSource(geometry, sourceCenter);
    offset = displayCenter - canvasCenter;
    placement = struct( ...
        'offset', offset, ...
        'xData', [1, size(geometry.canvas, 2)] + offset(1), ...
        'yData', [1, size(geometry.canvas, 1)] + offset(2));
end

function point = originalToPreviewSource(geometry, point)
    scale = 1;
    if isfield(geometry, 'coordinateScale') && isfinite(double(geometry.coordinateScale)) && ...
            double(geometry.coordinateScale) > 0
        scale = double(geometry.coordinateScale);
    end
    point = (point - 0.5) .* scale + 0.5;
end
