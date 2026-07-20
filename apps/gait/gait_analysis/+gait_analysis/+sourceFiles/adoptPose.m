% App-owned implementation for gait_analysis.sourceFiles.adoptPose within the gait_analysis product workflow.
function applicationState = adoptPose( ...
        applicationState, selection, callbackContext)
%ADOPTPOSE Apply source-owned timing, scale, and role facts after import.
arguments
    applicationState (1, 1) struct
    selection (1, 1) labkit.app.event.ListSelection
    callbackContext (1, 1) labkit.app.CallbackContext
end
pose = applicationState.session.cache.pose;
applicationState.project.results.analysis = ...
    gait_analysis.analysisRun.emptyResult();
applicationState.project.results.lastExport = [];
applicationState.session.cache.lastRunFingerprint = "";
applicationState.session.selection.currentStepIndex = 1;
if ~pose.ok || isempty(selection.Indices)
    return
end
applicationState.project.parameters = ...
    gait_analysis.analysisRun.optionsForPose( ...
        pose, applicationState.project.parameters);
callbackContext.appendStatus( ...
    "Loaded pose file: " + applicationState.session.cache.filepath);
end
