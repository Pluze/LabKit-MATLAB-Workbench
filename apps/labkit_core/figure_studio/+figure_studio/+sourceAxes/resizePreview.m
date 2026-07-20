% App-owned implementation for figure_studio.sourceAxes.resizePreview within the figure_studio product workflow.
function resizePreview(axesHandle, style)
%RESIZEPREVIEW Reapply the Figure Studio canvas policy after native reflow.
if isempty(style) || ~isfield(style, "canvasWidth") || ~isfield(style, "canvasHeight")
    return;
end
labkit.app.plot.fitCanvasToSource(axesHandle, style.canvasWidth, style.canvasHeight);
end
