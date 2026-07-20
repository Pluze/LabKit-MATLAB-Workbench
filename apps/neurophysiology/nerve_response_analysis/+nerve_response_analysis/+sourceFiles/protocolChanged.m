% App-owned implementation for nerve_response_analysis.sourceFiles.protocolChanged within the nerve_response_analysis product workflow.
function state = protocolChanged(state, selection, context)
%PROTOCOLCHANGED Record reader-facing optional protocol selection state.
arguments
    state (1, 1) struct
    selection (1, 1) labkit.app.event.ListSelection
    context (1, 1) labkit.app.CallbackContext
end
if isempty(selection.Indices)
    state.session.workflow.lastAction = "Cleared protocol";
    return;
end
state.session.workflow.lastAction = "Selected protocol";
context.appendStatus( ...
    "Selected protocol: " + state.session.cache.protocolPath);
end
