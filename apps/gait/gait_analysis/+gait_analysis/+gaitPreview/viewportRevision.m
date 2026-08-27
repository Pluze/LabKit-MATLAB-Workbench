% Expected caller: Gait Analysis presentation and direct tests. A new pose
% source, analysis result, or selected step changes the plotted coordinate
% window and refits; repaint-only state preserves the current viewport.
function revision = viewportRevision(sources, resultRevision)
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = reshape(string({sources.id}), 1, []);
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, "resultRevision", resultRevision)));
end
