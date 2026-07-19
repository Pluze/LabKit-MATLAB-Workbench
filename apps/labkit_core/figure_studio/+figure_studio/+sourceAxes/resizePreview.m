function resizePreview(axesHandle, style)
%RESIZEPREVIEW Reapply the Figure Studio canvas policy after native reflow.
if isempty(style) || ~isfield(style, "canvasWidth") || ~isfield(style, "canvasHeight")
    return;
end
labkit.app.plot.fitCanvasToSource(axesHandle, style.canvasWidth, style.canvasHeight);
end
