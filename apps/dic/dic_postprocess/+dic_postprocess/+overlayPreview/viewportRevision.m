% Expected caller: DIC Postprocess presentation and direct tests. Inputs are
% semantic source records and prepared overlays. Output changes only when the
% image canvas identity changes; pixel styling on the same canvas preserves zoom.
function revision = viewportRevision(sources, overlayExx, overlayEyy)
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = reshape(string({sources.id}), 1, []);
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, ...
    "exxSize", imageSize(overlayExx), ...
    "eyySize", imageSize(overlayEyy))));
end

function value = imageSize(imageData)
value = [0 0];
if ~isempty(imageData)
    value = [size(imageData, 1), size(imageData, 2)];
end
end
