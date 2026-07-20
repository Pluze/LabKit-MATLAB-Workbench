% App-owned implementation for dic_preprocess.analysisRun.startCropRoi within the dic_preprocess product workflow.
function applicationState = startCropRoi( ...
        applicationState, callbackContext)
%STARTCROPROI Begin a square crop interaction on the current pair.
if ~dic_preprocess.sourceFiles.hasImagePair(applicationState.session.cache)
    callbackContext.alert( ...
        "Load both reference and moving images before cropping.", ...
        "Missing images");
    return
end
applicationState = dic_preprocess.analysisRun.stopEditors(applicationState);
rectangle = dic_preprocess.analysisRun.defaultSquareRect( ...
    size(applicationState.session.cache.currentReferenceImage));
applicationState.project.annotations.cropRect = rectangle;
applicationState.project.parameters.previewMode = "Current pair";
applicationState.session.workflow.mode = "crop";
applicationState.session.workflow.details = ...
    dic_preprocess.analysisRun.cropSelectionSummary(rectangle);
callbackContext.appendStatus("Started crop ROI on the current pair.");
end
