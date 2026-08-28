function applicationState = selectOnCanvas(applicationState, indices, ~)
%SELECTONCANVAS Store ROI indices chosen by point click or marquee gesture.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
indices = unique(round(double(indices(:).')), "stable");
indices = indices(isfinite(indices) & indices >= 1 & ...
    indices <= numel(annotation.rois));
applicationState.session.selection.roiIndices = indices;
if isempty(indices)
    applicationState.session.selection.roiIndex = 0;
    applicationState.session.selection.roiCells = ...
        labkit.app.event.TableCellSelection(zeros(0, 2));
else
    applicationState.session.selection.roiIndex = indices(1);
    applicationState.session.selection.roiCells = ...
        labkit.app.event.TableCellSelection([indices(:), ones(numel(indices), 1)]);
end
end
