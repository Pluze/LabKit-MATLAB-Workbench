function draw(axesById, model)
%DRAW Render the declared fused-image and focus-map axes.
fused = axesById.fused;
map = axesById.focusMap;
cla(fused); cla(map);
title(fused, "Fused all-in-focus image");
title(map, "Focus-depth index map");
if model.result.ok
    imshow(model.result.fused, "Parent", fused);
    title(fused, "Fused all-in-focus image");
    imshow(focus_stack.focusPreview.focusIndexRgb( ...
        model.result.focusIndex, model.result.inputCount), "Parent", map);
    title(map, "Focus-depth index map");
elseif ~isempty(model.images)
    imshow(model.images{1}, "Parent", fused);
    title(fused, "First source image");
end
end
