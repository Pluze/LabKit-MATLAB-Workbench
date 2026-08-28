function applicationState = pasteSelected(applicationState, ~)
%PASTESELECTED Arm copied ROIs for placement by the next image click.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
if isempty(applicationState.session.clipboard.rois) || ...
        strlength(annotation.sourceId) == 0
    return
end
applicationState.session.clipboard.pastePending = ...
    ~applicationState.session.clipboard.pastePending;
end
