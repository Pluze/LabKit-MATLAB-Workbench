function applicationState = changeWidth(applicationState, value, ~)
%CHANGEWIDTH Change the selected ROI template width without moving centers.
applicationState = changeSize(applicationState, value, 1);
end

function state = changeSize(state, value, dimension)
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(state);
index = state.session.selection.roiIndex;
value = double(value);
if index < 1 || index > numel(annotation.rois) || ...
        ~isscalar(value) || ~isfinite(value) || value < 1
    return
end
templates = state.project.annotations.templates;
match = find(string({templates.id}) == annotation.rois(index).templateId, 1);
templates(match).size(dimension) = round(value);
if templates(match).shape == "Square" || templates(match).shape == "Circle"
    templates(match).size(:) = round(value);
end
state.project.annotations.templates = templates;
state.project.results = roi_analyzer.analysisRun.invalidateAll(state.project.results);
end
