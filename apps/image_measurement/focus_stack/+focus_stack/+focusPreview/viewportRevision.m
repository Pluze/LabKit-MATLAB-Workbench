% Expected caller: Focus Stack preview presentation and direct tests. Source
% identity, result availability, and successful result generation own the two
% image canvases. Status, export, and registration-detail refreshes preserve zoom.
function revision = viewportRevision(sources, hasResult, resultRevision)
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = reshape(string({sources.id}), 1, []);
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, ...
    "hasResult", logical(hasResult), ...
    "resultRevision", resultRevision)));
end
