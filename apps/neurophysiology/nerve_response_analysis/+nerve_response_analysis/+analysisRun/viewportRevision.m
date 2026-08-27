% Expected caller: Nerve Response Analysis presentation and direct tests.
% Source identity, accepted result generation, and Counts/Issues view choice
% own the chart domain. Status, output-folder, and export updates preserve zoom.
function revision = viewportRevision(sources, previewMode, resultRevision)
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = reshape(string({sources.id}), 1, []);
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, ...
    "previewMode", string(previewMode), ...
    "resultRevision", resultRevision)));
end
