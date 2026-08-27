% Expected caller: Batch Crop preview presentation and direct tests. Inputs are
% the selected crop task and prepared geometry. Output changes for a new source
% or canvas transform, while crop/scale overlays on that canvas preserve zoom.
function revision = viewportRevision(item, geometry)
sourceId = "";
angleDeg = 0;
paddingPercent = 0;
canvasSize = [0 0];
if isstruct(item) && ~isempty(fieldnames(item))
    sourceId = string(item.sourceId);
    angleDeg = double(item.angleDeg);
    paddingPercent = double(item.paddingPercent);
end
if isstruct(geometry) && isfield(geometry, "canvas") && ...
        ~isempty(geometry.canvas)
    canvasSize = [size(geometry.canvas, 1), size(geometry.canvas, 2)];
end
revision = string(jsonencode(struct( ...
    "sourceId", sourceId, ...
    "angleDeg", angleDeg, ...
    "paddingPercent", paddingPercent, ...
    "canvasSize", canvasSize)));
end
