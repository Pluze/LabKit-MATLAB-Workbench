function applicationState = remove(applicationState, ~)
%REMOVE Delete selected ROIs and repair the reference selection.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
indices = roi_analyzer.roiLibrary.selectedIndices( ...
    applicationState.session.selection, numel(annotation.rois));
if isempty(indices)
    return
end
removedIds = string({annotation.rois(indices).id});
annotation.rois(indices) = [];
if any(applicationState.project.parameters.ratioDenominatorRoiId == removedIds)
    applicationState.project.parameters.ratioDenominatorRoiId = "";
end
applicationState = roi_analyzer.roiLibrary.storeAnnotation( ...
    applicationState, annotation);
applicationState.session.selection.roiIndex = min(indices(1), numel(annotation.rois));
applicationState.session.selection.roiIndices = ...
    applicationState.session.selection.roiIndex;
end
