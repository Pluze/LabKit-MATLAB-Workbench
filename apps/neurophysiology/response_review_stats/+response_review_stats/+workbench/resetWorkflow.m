function state = resetWorkflow(state, context)
%RESETWORKFLOW Restore a new Response Review Stats project and session.
state.project = response_review_stats.initialData();
state.session = response_review_stats.createSession(state.project, context);
context.log("info", "response_review_stats.workbench.resetworkflow.completed", ...
    "Reset Response Review Stats state.");
end
