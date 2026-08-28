function applicationState = changeHeight(applicationState, value, ~)
%CHANGEHEIGHT Change the selected ROI template height without moving centers.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
index = applicationState.session.selection.roiIndex;
value = double(value);
if index < 1 || index > numel(annotation.rois) || ...
        ~isscalar(value) || ~isfinite(value) || value < 1
    return
end
templates = applicationState.project.annotations.templates;
match = find(string({templates.id}) == annotation.rois(index).templateId, 1);
templates(match).size(2) = round(value);
if templates(match).shape == "Square" || templates(match).shape == "Circle"
    templates(match).size(:) = round(value);
end
applicationState.project.annotations.templates = templates;
applicationState = roi_analyzer.analysisRun.invalidateAll(applicationState);
end
