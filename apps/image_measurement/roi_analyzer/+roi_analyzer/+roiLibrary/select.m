function applicationState = select(applicationState, selection, ~)
%SELECT Choose one or more ROI rows from the current-image table.
if isempty(selection.CellIndices)
    return
end
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
indices = unique(selection.CellIndices(:, 1).', "stable");
indices = indices(indices >= 1 & indices <= numel(annotation.rois));
if isempty(indices)
    return
end
applicationState.session.selection.roiIndex = indices(1);
applicationState.session.selection.roiIndices = indices;
applicationState.session.selection.roiCells = selection;
end
