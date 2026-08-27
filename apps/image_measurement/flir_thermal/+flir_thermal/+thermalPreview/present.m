% App-owned implementation for flir_thermal.thermalPreview.present within the flir_thermal product workflow.
function view = present(item, parameters, range, viewRevision)
%PRESENT Prepare the paired thermal image/scale model and reading gesture.
model = flir_thermal.thermalPreview.model(item, parameters, range);
imageSize = [];
if ~isempty(item)
    values = ...
        flir_thermal.thermalPreview.presentationData.valueMatrix(item);
    imageSize = size(values);
end
view = labkit.app.view.Snapshot() ...
    .renderPlot("preview", model, ViewRevision=viewRevision) ...
    .regionSelection("temperatureReading", ...
        ImageSize=imageSize, Enabled=~isempty(item));
end
