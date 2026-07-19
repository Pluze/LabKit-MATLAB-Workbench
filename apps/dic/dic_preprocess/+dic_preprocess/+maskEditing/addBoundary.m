function applicationState = addBoundary(applicationState, callbackContext)
applicationState = dic_preprocess.maskEditing.applyBoundary( ...
    applicationState, callbackContext, "add");
end
