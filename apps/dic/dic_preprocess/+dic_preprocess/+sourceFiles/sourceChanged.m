% App-owned implementation for dic_preprocess.sourceFiles.sourceChanged within the dic_preprocess product workflow.
function applicationState = sourceChanged( ...
        applicationState, selection, callbackContext)
%SOURCECHANGED Reset pair-derived annotations after either source changes.
arguments
    applicationState (1, 1) struct
    selection (1, 1) labkit.app.event.ListSelection
    callbackContext (1, 1) labkit.app.CallbackContext
end
applicationState.project = ...
    dic_preprocess.editHistory.resetForNewInput(applicationState.project);
cache = applicationState.session.cache;
applicationState.session.cache = ...
    dic_preprocess.analysisRun.replayEditSteps( ...
        cache.referenceImage, cache.movingImage, ...
        applicationState.project.annotations.editSteps);
applicationState.session.workflow.mode = "idle";
applicationState.project.parameters.previewMode = ...
    dic_preprocess.analysisRun.defaultPreviewMode(applicationState);
applicationState.project.results.currentImagesManifestPath = "";
applicationState.project.results.maskManifestPath = "";
if ~isempty(selection.Indices)
    callbackContext.log("info", "dic_preprocess.sourcefiles.sourcechanged.status", "Updated DIC source image.");
end
end
