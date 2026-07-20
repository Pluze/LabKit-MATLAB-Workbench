function draw(axesById, model)
%DRAW Render one selected Image Match preview.
axesHandle = axesById.image;
labkit.app.plot.clearAxes(axesHandle);
title(axesHandle, model.title);
if isempty(model.imageData)
    return;
end
imshow(model.imageData, Parent=axesHandle);
title(axesHandle, model.title);
end
