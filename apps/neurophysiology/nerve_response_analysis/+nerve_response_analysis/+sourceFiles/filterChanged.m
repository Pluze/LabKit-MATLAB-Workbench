function state = filterChanged(state, selection, context)
%FILTERCHANGED Record reader-facing filter selection state after rebuild.
arguments
    state (1, 1) struct
    selection (1, 1) labkit.app.event.ListSelection
    context (1, 1) labkit.app.CallbackContext
end
if isempty(selection.Indices)
    state.session.workflow.lastAction = "Cleared filter record";
    return;
end
state.session.workflow.statusMessage = "Filter record selected.";
state.session.workflow.lastAction = "Selected filter record";
context.appendStatus( ...
    "Selected filter record: " + state.session.cache.filterPath);
end
