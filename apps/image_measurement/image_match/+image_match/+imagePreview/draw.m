function draw(axesById, model)
%DRAW Render the selected image-match preview without owning app state.
ax = axesById.image;
labkit.app.plot.clearAxes(ax);
if isempty(model.source)
    labkit.app.plot.showMessage(ax, "Load source images");
    return
end
imageData = model.source.image;
if model.mode == "Matched" && ~isempty(model.result)
    imageData = model.result;
end
imshow(imageData, Parent=ax);
title(ax, model.mode);
end
