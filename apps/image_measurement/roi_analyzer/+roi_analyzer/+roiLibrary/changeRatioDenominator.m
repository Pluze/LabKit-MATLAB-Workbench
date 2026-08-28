function applicationState = changeRatioDenominator(applicationState, value, ~)
%CHANGERATIODENOMINATOR Select the ROI used as a same-channel mean denominator.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
label = string(value);
if label == "None"
    applicationState.project.parameters.ratioDenominatorRoiId = "";
else
    match = find(string({annotation.rois.name}) == label, 1);
    if isempty(match)
        return
    end
    applicationState.project.parameters.ratioDenominatorRoiId = ...
        annotation.rois(match).id;
end
applicationState = roi_analyzer.analysisRun.invalidateAll(applicationState);
end
