% App-owned implementation for figure_studio.sourceAxes.resizePreview within the figure_studio product workflow.
function resizePreview(axesHandle, style)
%RESIZEPREVIEW Retain the native preview allocation after native reflow.
% Figure Studio reserves canvas dimensions for export; changing them must not
% replace the user's current preview viewport or plot allocation.
if isempty(axesHandle) || ~isvalid(axesHandle) || isempty(style)
    return;
end
end
