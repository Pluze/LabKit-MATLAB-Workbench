% App-owned implementation for rhs_preview.workbench.resetWorkflow within the rhs_preview product workflow.
function applicationState = resetWorkflow( ...
        applicationState, callbackContext)
%RESETWORKFLOW Restore a new RHS Preview project and transient session.
applicationState.project = rhs_preview.initialData();
applicationState.session = rhs_preview.createSession( ...
    applicationState.project, callbackContext);
callbackContext.log("info", "rhs_preview.workbench.resetworkflow.completed", ...
    "Reset RHS Preview state.");
end
