% Expected caller: Curvature workbench presentation and direct tests. Inputs
% are semantic source records and decoded image pixels. Output changes for a
% new image canvas; curve, fit, calibration, and visibility edits preserve zoom.
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
