function applicationState = changeName(applicationState, value, ~)
%CHANGENAME Rename the selected ROI.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
index = applicationState.session.selection.roiIndex;
name = strip(string(value));
if index < 1 || index > numel(annotation.rois) || strlength(name) == 0
    return
end
otherNames = string({annotation.rois.name});
otherNames(index) = [];
if any(otherNames == name)
    return
end
annotation.rois(index).name = name;
applicationState = roi_analyzer.roiLibrary.storeAnnotation( ...
    applicationState, annotation);
end
