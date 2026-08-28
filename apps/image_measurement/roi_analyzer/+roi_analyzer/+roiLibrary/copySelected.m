function applicationState = copySelected(applicationState, ~)
%COPYSELECTED Copy selected ROIs with their relative center placement.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
indices = roi_analyzer.roiLibrary.selectedIndices( ...
    applicationState.session.selection, numel(annotation.rois));
if isempty(indices)
    return
end
rois = annotation.rois(indices);
applicationState.session.clipboard.rois = rois;
applicationState.session.clipboard.anchor = mean(vertcat(rois.centerXY), 1);
applicationState.session.clipboard.sourceId = annotation.sourceId;
end
