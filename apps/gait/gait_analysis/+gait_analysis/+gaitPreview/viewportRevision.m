% Expected caller: Gait Analysis presentation and direct tests. A new pose
% source, analysis result, or selected step changes the plotted coordinate
% window and refits. Display calibration also changes the spatial domain;
% pending detection settings preserve the already-invalidated preview.
function revision = viewportRevision(sources, resultRevision, displayOptions)
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = reshape(string({sources.id}), 1, []);
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, "resultRevision", resultRevision, ...
    "display", displayOptions)));
end
