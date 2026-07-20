% App-owned implementation for rhs_preview.workbench.resetWorkflow within the rhs_preview product workflow.
function applicationState = resetWorkflow( ...
        applicationState, callbackContext)
%RESETWORKFLOW Restore a new RHS Preview project and transient session.
schema = rhs_preview.projectSpec();
applicationState.project = schema.Create();
applicationState.session = rhs_preview.createSession( ...
    applicationState.project, callbackContext);
callbackContext.appendStatus("Reset RHS Preview state.");
end
