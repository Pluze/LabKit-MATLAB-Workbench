function applicationState = cancelPointMatching( ...
        applicationState, callbackContext)
if applicationState.session.workflow.mode ~= "matching"
    return
end
applicationState = dic_preprocess.analysisRun.stopEditors(applicationState);
applicationState.session.workflow.details = {'Point matching cancelled.'};
callbackContext.log("info", "dic_preprocess.analysisrun.cancelpointmatching.status", "Cancelled point matching.");
end
