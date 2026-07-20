function lines = summaryLines(applicationState)
%SUMMARYLINES Build the DIC preprocessing summary shown by workbench.present.
% Input is canonical App state. Output is a string column containing source,
% current-pair, edit-history, alignment, and mask availability. No state or
% graphics are modified.

project = applicationState.project;
cache = applicationState.session.cache;
annotations = project.annotations;
lines = [
    "Reference: " + sourceReference(project.inputs.sources, "referenceImage")
    "Moving: " + sourceReference(project.inputs.sources, "movingImage")
    "Current pair: " + currentPairSize(cache)
    "Undo steps: " + string(numel(annotations.history))
    "Last aligned image: " + availability(any( ...
        string({annotations.editSteps.kind}) == "alignment"), ...
        "available", "not generated")
    "ROI mask: " + availability(~isempty(annotations.maskImage), ...
        "available", "not drawn")];
end

function value = sourceReference(sources, role)
value = "none";
if isempty(sources)
    return
end
index = find(string({sources.role}) == role, 1);
if isempty(index)
    return
end
candidate = string(sources(index).reference.originalPath);
if strlength(candidate) > 0
    value = candidate;
end
end

function value = currentPairSize(cache)
if isempty(cache.currentReferenceImage) || isempty(cache.currentMovingImage)
    value = "not loaded";
    return
end
value = sprintf("reference %d x %d, moving %d x %d", ...
    size(cache.currentReferenceImage, 1), ...
    size(cache.currentReferenceImage, 2), ...
    size(cache.currentMovingImage, 1), ...
    size(cache.currentMovingImage, 2));
end

function value = availability(condition, available, unavailable)
value = unavailable;
if condition
    value = available;
end
end
