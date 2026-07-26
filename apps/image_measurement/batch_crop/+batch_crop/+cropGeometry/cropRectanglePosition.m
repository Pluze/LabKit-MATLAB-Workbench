% App-owned crop-ROI geometry helper. Expected callers: Batch Crop preview
% presentation and managed-ROI callbacks. Inputs are a prepared canvas,
% original-image center, and [width height] crop size. Output is one finite
% [x y width height] canvas rectangle; it has no state or graphics effects.
function position = cropRectanglePosition(geometry, center, cropSize)
%CROPRECTANGLEPOSITION Return the preview-canvas crop rectangle position.

scale = batch_crop.cropGeometry.geometryScale(geometry);
width = max(1, double(cropSize(1)) * scale);
height = max(1, double(cropSize(2)) * scale);
canvasCenter = batch_crop.cropGeometry.originalToCanvas(geometry, center);
position = [round(canvasCenter(1) - (width - 1) / 2) - 0.5, ...
    round(canvasCenter(2) - (height - 1) / 2) - 0.5, width, height];
end
