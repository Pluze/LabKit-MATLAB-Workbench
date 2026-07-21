%SELECTPANEL Decode exactly one selected FIG axes for Figure Studio.
% Expected callers: Figure Studio source selection and session restoration.
% Input is a native source resource and one-based panel index. Output is the
% selected axes plus portable data and source presentation for that panel.
function [plotData, sourceStyle, sourceAxes, panelLabel, panelIndex] = ...
        selectPanel(resource, requestedIndex)
arguments
    resource (1, 1) struct
    requestedIndex (1, 1) double {mustBeInteger, mustBePositive}
end
if ~isfield(resource, "axes")
    error("figure_studio:sourceAxes:InvalidResource", ...
        "The FIG source resource does not contain plotting axes.");
end
[axesHandles, labels] = figure_studio.sourceAxes.panelChoices(resource.axes);
if isempty(axesHandles)
    error("labkit_FigureStudio_app:NoAxes", ...
        "The selected FIG file does not contain plotting axes.");
end
panelIndex = min(requestedIndex, numel(axesHandles));
sourceAxes = axesHandles(panelIndex);
panelLabel = labels(panelIndex);
sourceStyle = figure_studio.sourceAxes.sourceStyle(sourceAxes, ...
    "PreserveAspect", false);
plotData = figure_studio.resultFiles.extractAxesData(sourceAxes);
end
