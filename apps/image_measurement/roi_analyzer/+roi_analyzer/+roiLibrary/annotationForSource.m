function annotation = annotationForSource(items, sourceId)
%ANNOTATIONFORSOURCE Return the ROI collection for one source identity.
match = find(string({items.sourceId}) == string(sourceId), 1);
if isempty(match)
    annotation = struct("sourceId", string(sourceId), "rois", ...
        repmat(roi_analyzer.roiLibrary.emptyRoi(), 0, 1));
else
    annotation = items(match);
end
end
