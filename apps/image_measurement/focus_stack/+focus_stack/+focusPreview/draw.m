% App-owned implementation for focus_stack.focusPreview.draw within the focus_stack product workflow.
function draw(axesById, model)
%DRAW Render the declared fused-image and focus-map axes.
fused = axesById.fused;
map = axesById.focusMap;
cla(fused); cla(map);
title(fused, "Fused all-in-focus image");
title(map, "Focus-depth index map");
if model.result.ok
    showImage(fused, model.result.fused);
    title(fused, "Fused all-in-focus image");
    showImage(map, focus_stack.focusPreview.focusIndexRgb( ...
        model.result.focusIndex, model.result.inputCount));
    title(map, "Focus-depth index map");
elseif ~isempty(model.images)
    showImage(fused, model.images{1});
    title(fused, "First source image");
end
end

function showImage(axesHandle, imageData)
image(axesHandle, imageData);
axis(axesHandle, "image");
axis(axesHandle, "off");
end
