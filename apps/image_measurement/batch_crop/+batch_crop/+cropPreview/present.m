% App-owned implementation for batch_crop.cropPreview.present within the batch_crop product workflow.
function view = present(applicationState)
%PRESENT Describe preview pixels and both managed interactions.
[model, geometry, item] = previewModel(applicationState);
hasImage = ~isempty(model.imageData);
editing = hasImage && ...
    applicationState.session.workflow.scaleReferenceEditing;
imageSize = [1 1];
centerValue = zeros(0, 2);
reference = zeros(0, 2);
if hasImage
    imageSize = [size(geometry.canvas, 1), size(geometry.canvas, 2)];
    centerValue = batch_crop.cropGeometry.originalToCanvas( ...
        geometry, item.centerXY);
    reference = item.scaleCalibration.referenceLine;
    for k = 1:size(reference, 1)
        reference(k, :) = batch_crop.cropGeometry.originalToCanvas( ...
            geometry, reference(k, :));
    end
end
view = labkit.app.view.Snapshot() ...
    .renderPlot("preview", model) ...
    .pointSlots("cropCenter", centerValue, ...
        ImageSize=imageSize, Enabled=hasImage && ~editing) ...
    .scaleReference("scaleReference", reference, ...
        ImageSize=imageSize, Enabled=editing);
end

function [model, geometry, item] = previewModel(state)
model = struct("imageData", [], "xData", [1 1], "yData", [1 1], ...
    "center", [1 1], "cropRectangle", [], "scaleBar", [], ...
    "title", "Padded rotation preview + fixed crop");
geometry = struct();
item = struct();
if ~batch_crop.sourceFiles.hasCurrentImage(state)
    return
end
index = batch_crop.sourceFiles.currentIndex(state);
item = batch_crop.sourceFiles.currentItem(state);
[geometry, ~] = batch_crop.cropGeometry.currentGeometry( ...
    state.session.cache.canvas, index, item, item.paddingPercent);
placement = batch_crop.cropPreview.placement(geometry);
render = batch_crop.cropPreview.renderData(geometry, placement);
model.imageData = render.imageData;
model.xData = [1 size(geometry.canvas, 2)];
model.yData = [1 size(geometry.canvas, 1)];
model.center = batch_crop.cropGeometry.originalToCanvas( ...
    geometry, item.centerXY);
model.cropRectangle = cropRectangle(geometry, item.centerXY, ...
    batch_crop.cropGeometry.currentCropSize(state));
model.scaleBar = scaleBarOnCanvas(geometry, state.session.view.scaleBar);
end

function position = cropRectangle(geometry, center, cropSize)
scale = batch_crop.cropGeometry.geometryScale(geometry);
width = max(1, double(cropSize(1)) * scale);
height = max(1, double(cropSize(2)) * scale);
canvasCenter = batch_crop.cropGeometry.originalToCanvas(geometry, center);
position = [round(canvasCenter(1) - (width - 1) / 2) - 0.5, ...
    round(canvasCenter(2) - (height - 1) / 2) - 0.5, width, height];
end

function value = scaleBarOnCanvas(geometry, value)
if isempty(value)
    return
end
for k = 1:size(value.line, 1)
    value.line(k, :) = batch_crop.cropGeometry.originalToCanvas( ...
        geometry, value.line(k, :));
end
value.labelPosition = batch_crop.cropGeometry.originalToCanvas( ...
    geometry, value.labelPosition);
end
