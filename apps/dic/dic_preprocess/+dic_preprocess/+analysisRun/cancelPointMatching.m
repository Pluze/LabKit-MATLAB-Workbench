function applicationState = cancelPointMatching( ...
        applicationState, callbackContext)
if applicationState.session.workflow.mode ~= "matching"
    return
end
applicationState = dic_preprocess.analysisRun.stopEditors(applicationState);
applicationState.session.workflow.details = {'Point matching cancelled.'};
callbackContext.appendStatus("Cancelled point matching.");
end
