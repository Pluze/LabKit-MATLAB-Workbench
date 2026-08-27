% Expected caller: Image Enhance workbench presentation and direct tests.
% Source identity, preview composition, and displayed canvas size own viewport
% fitting. Enhancement pixels, ROI overlays, and tool controls preserve zoom.
function revision = viewportRevision(sourceId, previewMode, imageData)
imageSize = [0 0];
if ~isempty(imageData)
    imageSize = [size(imageData, 1), size(imageData, 2)];
end
revision = string(jsonencode(struct( ...
    "sourceId", string(sourceId), ...
    "composition", composition(previewMode), ...
    "imageSize", imageSize)));
end

function value = composition(previewMode)
value = "single";
if string(previewMode) == "Before | After"
    value = "comparison";
end
end
