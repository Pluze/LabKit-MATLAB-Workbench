% App-owned implementation for nerve_response_analysis.workbench.resetWorkflow within the nerve_response_analysis product workflow.
function state = resetWorkflow(state, context)
%RESETWORKFLOW Restore a new Nerve Response Analysis project and session.
state.project = nerve_response_analysis.initialData();
state.session = nerve_response_analysis.createSession( ...
    state.project, context);
context.log("info", "nerve_response_analysis.workbench.resetworkflow.completed", ...
    "Reset Nerve Response Analysis state.");
end
