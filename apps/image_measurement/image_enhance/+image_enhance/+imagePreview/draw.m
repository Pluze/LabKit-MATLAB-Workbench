% App-owned implementation for image_enhance.imagePreview.draw within the image_enhance product workflow.
function draw(axesById, model)
%DRAW Render the selected Image Enhance preview and display-only ROI.
axesHandle = axesById.image;
labkit.app.plot.clearAxes(axesHandle);
title(axesHandle, model.title);
if isempty(model.imageData)
    return;
end
imshow(model.imageData, Parent=axesHandle);
title(axesHandle, model.title);
if numel(model.whiteRoi) == 4 && ...
        all(isfinite(model.whiteRoi)) && all(model.whiteRoi(3:4) > 0)
    rectangle(axesHandle, Position=model.whiteRoi, ...
        EdgeColor=[1 1 1], LineWidth=1.5, ...
        HitTest="off", PickableParts="none");
end
end
