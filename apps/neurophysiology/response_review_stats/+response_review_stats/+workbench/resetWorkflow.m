function state = resetWorkflow(state, context)
%RESETWORKFLOW Restore a new Response Review Stats project and session.
schema = response_review_stats.projectSpec();
state.project = schema.Create();
state.session = response_review_stats.createSession(state.project, context);
context.appendStatus("Reset Response Review Stats state.");
end
