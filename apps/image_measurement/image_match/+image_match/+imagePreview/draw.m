% App-owned implementation for image_match.imagePreview.draw within the image_match product workflow.
function draw(axesById, model)
%DRAW Render one selected Image Match preview.
axesHandle = axesById.image;
labkit.app.plot.clearAxes(axesHandle);
title(axesHandle, model.title);
if isempty(model.imageData)
    return;
end
image(axesHandle, model.imageData);
axis(axesHandle, "image");
axis(axesHandle, "off");
title(axesHandle, model.title);
end
