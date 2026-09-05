% App-owned implementation for focus_stack.focusPreview.draw within the focus_stack product workflow.
function draw(axesById, model)
%DRAW Render the declared fused-image, source-index, and relative-confidence axes.
fused = axesById.fused;
map = axesById.focusMap;
confidence = axesById.confidence;
cla(fused); cla(map); cla(confidence);
colorbar(confidence, "off");
title(confidence, "Focus confidence (0–1)");
title(fused, "Fused all-in-focus image");
title(map, "Focus-depth index map");
if model.result.ok
    showImage(fused, model.result.fused);
    title(fused, "Fused all-in-focus image");
    showImage(map, focus_stack.focusPreview.focusIndexRgb( ...
        model.result.focusIndex, model.result.inputCount));
    title(map, "Focus-depth index map");
    imagesc(confidence, model.result.confidence, [0 1]);
    axis(confidence, "image");
    axis(confidence, "off");
    colormap(confidence, parula(256));
    scale = colorbar(confidence);
    scale.Label.String = "Relative detail-score separation";
    title(confidence, "Focus confidence (0–1)");
elseif ~isempty(model.images)
    showImage(fused, model.images{1});
    title(fused, "First source image");
end
end

function showImage(axesHandle, imageData)
image(axesHandle, labkit.image.ensureRgb(imageData));
axis(axesHandle, "image");
axis(axesHandle, "off");
end
