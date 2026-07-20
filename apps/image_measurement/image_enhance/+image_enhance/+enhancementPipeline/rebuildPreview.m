function applicationState = rebuildPreview(applicationState)
%REBUILDPREVIEW Recompute the selected display-resolution enhancement.
cache = applicationState.session.cache;
if isempty(cache.previewSource)
    applicationState.session.cache.previewResult = [];
    applicationState.session.cache.previewResultKey = "";
    return;
end
steps = image_enhance.analysisRun.activeSteps(applicationState);
availability = ...
    image_enhance.imagePreview.presentationData.toolAvailability( ...
        applicationState, applicationState.session.view.toolKind);
includePending = ...
    applicationState.session.workflow.pendingDirty && ...
    availability.canPreviewPending;
previewSteps = steps;
if includePending
    previewSteps(end + 1, 1) = image_enhance.analysisRun.makeStep( ...
        applicationState.session.view.toolKind, ...
        applicationState.session.view.toolAmount, ...
        applicationState.session.view.toolSecondary, 0);
end
key = previewKey(previewSteps, includePending);
if cache.previewResultKey == key && ~isempty(cache.previewResult)
    return;
end
roi = currentWhiteRoi(applicationState);
applicationState.session.cache.previewResult = ...
    image_enhance.analysisRun.previewResult( ...
        cache.previewSource, previewSteps, roi, cache.previewScale);
applicationState.session.cache.previewResultKey = key;
end

function key = previewKey(steps, includePending)
if isempty(steps)
    key = "steps=0#pending=" + string(includePending);
    return;
end
labels = string({steps.label});
key = strjoin(labels, "|") + ...
    "#steps=" + string(numel(steps)) + ...
    "#pending=" + string(includePending);
end

function roi = currentWhiteRoi(applicationState)
roi = [];
index = applicationState.session.selection.currentIndex;
sources = applicationState.project.inputs.sources;
if applicationState.project.parameters.batchMode || ...
        index < 1 || index > numel(sources)
    return;
end
annotation = image_enhance.sourceLibrary.annotationForSource( ...
    applicationState.project.annotations.items, sources(index).id);
roi = annotation.whiteRoi;
end
