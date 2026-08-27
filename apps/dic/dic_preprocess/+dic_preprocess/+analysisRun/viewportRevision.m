% Expected caller: DIC Preprocess presentation and direct tests. New source
% identities, displayed canvas geometry, and committed crop operations refit;
% point, mask, alignment, and same-canvas preview edits preserve zoom.
function revision = viewportRevision(sources, model, cropRevision)
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = reshape(string({sources.id}), 1, []);
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, ...
    "referenceSize", imageSize(model.reference.imageData), ...
    "movingSize", imageSize(model.moving.imageData), ...
    "cropRevision", cropRevision)));
end

function value = imageSize(imageData)
value = [0 0];
if ~isempty(imageData)
    value = [size(imageData, 1), size(imageData, 2)];
end
end
