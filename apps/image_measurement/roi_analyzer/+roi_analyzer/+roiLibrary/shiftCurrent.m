function applicationState = shiftCurrent(applicationState, ~)
%SHIFTCURRENT Offset all current-image ROI centers by the entered pixels.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
delta = [applicationState.session.view.shiftX, ...
    applicationState.session.view.shiftY];
if isempty(annotation.rois) || any(~isfinite(delta))
    return
end
for k = 1:numel(annotation.rois)
    annotation.rois(k).centerXY = annotation.rois(k).centerXY + delta;
end
resolved = roi_analyzer.roiTemplates.resolve(annotation.rois, ...
    applicationState.project.annotations.templates, ...
    size(applicationState.session.cache.image));
for k = 1:numel(annotation.rois)
    annotation.rois(k).centerXY = resolved(k).centerXY;
end
applicationState = roi_analyzer.roiLibrary.storeAnnotation( ...
    applicationState, annotation);
end
