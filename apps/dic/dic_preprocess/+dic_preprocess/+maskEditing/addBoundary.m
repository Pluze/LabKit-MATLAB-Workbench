% App-owned implementation for dic_preprocess.maskEditing.addBoundary within the dic_preprocess product workflow.
function applicationState = addBoundary(applicationState, callbackContext)
applicationState = dic_preprocess.maskEditing.applyBoundary( ...
    applicationState, callbackContext, "add");
end
