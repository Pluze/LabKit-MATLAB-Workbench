% App-owned implementation for image_match.matchPipeline.refreshPreview within the image_match product workflow.
function cache = refreshPreview(cache, steps)
%REFRESHPREVIEW Replay explicit match steps into the transient preview cache.
%
% Expected callers: matchPipeline transaction callbacks. Inputs contain only
% the transient image cache and ordered semantic steps. The returned cache
% preserves unrelated fields and replaces preview images when both current
% and reference inputs are available.
if isempty(cache.currentItem) || isempty(cache.referenceItem)
    return
end

cache.previewSource = ...
    image_match.imagePreview.presentationData.previewImage( ...
        cache.currentItem.image);
cache.previewReference = ...
    image_match.imagePreview.presentationData.previewImage( ...
        cache.referenceItem.image);
processed = image_match.analysisRun.applyPipeline( ...
    {cache.previewSource}, steps, cache.previewReference);
cache.previewResult = processed{1};
end
