function state = resetWorkflow(state, context)
%RESETWORKFLOW Restore a new Nerve Response Analysis project and session.
schema = nerve_response_analysis.projectSpec();
state.project = schema.Create();
state.session = nerve_response_analysis.createSession( ...
    state.project, context);
context.appendStatus("Reset Nerve Response Analysis state.");
end
