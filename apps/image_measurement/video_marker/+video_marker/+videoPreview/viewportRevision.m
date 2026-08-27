% Expected caller: Video Marker workbench presentation and direct tests.
% Video source identity and frame canvas size own fitting. Same-size frame
% navigation, marker edits, skeleton overlays, and scale bars preserve zoom.
function revision = viewportRevision(sources, imageData)
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = reshape(string({sources.id}), 1, []);
end
imageSize = [0 0];
if ~isempty(imageData)
    imageSize = [size(imageData, 1), size(imageData, 2)];
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, "imageSize", imageSize)));
end
