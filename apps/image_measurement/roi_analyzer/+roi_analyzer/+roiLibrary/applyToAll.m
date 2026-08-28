function applicationState = applyToAll(applicationState, callbackContext)
%APPLYTOALL Copy current ROI names, shapes, and coordinates to every image.
[sourceAnnotation, sourceIndex] = ...
    roi_analyzer.roiLibrary.currentAnnotation(applicationState);
sources = applicationState.project.inputs.sources;
if sourceIndex < 1 || isempty(sourceAnnotation.rois)
    callbackContext.alert("Create at least one ROI before applying a layout.", ...
        "No ROI layout");
    return
end
for k = 1:numel(sources)
    annotation = sourceAnnotation;
    annotation.sourceId = string(sources(k).id);
    applicationState = roi_analyzer.roiLibrary.storeAnnotation( ...
        applicationState, annotation);
end
callbackContext.log("info", "roi_analyzer.roilibrary.applytoall.completed", ...
    "Applied the current ROI layout to all loaded images.", ...
    Attributes=struct("count", numel(sources)));
end
