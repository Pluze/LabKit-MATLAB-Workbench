%EXTRACTPANELSNAPSHOTS Decode every ordered axes in one source resource.
% Expected callers are Figure Studio source loading and panel selection. The
% returned cell array is ordered exactly like panelChoices and contains only
% the visible portable presentation state for each axes.
function [snapshots, axesHandles, labels] = extractPanelSnapshots(resource)
if ~isstruct(resource) || ~isfield(resource, "axes")
    error("figure_studio:sourceAxes:InvalidResource", ...
        "The FIG source resource does not contain plotting axes.");
end
[axesHandles, labels] = figure_studio.sourceAxes.panelChoices(resource.axes);
if isempty(axesHandles)
    error("labkit_FigureStudio_app:NoAxes", ...
        "The selected FIG file does not contain plotting axes.");
end
snapshots = cell(numel(axesHandles), 1);
for k = 1:numel(axesHandles)
    snapshots{k} = figure_studio.resultFiles.extractAxesData(axesHandles(k));
end
end
