function applicationState = changeShape(applicationState, value, ~)
%CHANGESHAPE Change the selected ROI's reusable geometry template.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
index = applicationState.session.selection.roiIndex;
shape = string(value);
if index < 1 || index > numel(annotation.rois) || ...
        ~any(shape == ["Rectangle" "Square" "Circle"])
    return
end
templates = applicationState.project.annotations.templates;
match = find(string({templates.id}) == annotation.rois(index).templateId, 1);
templates(match).shape = shape;
if shape == "Square" || shape == "Circle"
    side = min(templates(match).size);
    templates(match).size = [side side];
end
applicationState.project.annotations.templates = templates;
applicationState = roi_analyzer.analysisRun.invalidateAll(applicationState);
end
