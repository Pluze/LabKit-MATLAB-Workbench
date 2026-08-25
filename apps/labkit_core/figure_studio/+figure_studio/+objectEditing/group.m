function state = group(state, callbackContext)
before = state.session.editor.document;
try
    [document, groupId] = figure_studio.figureDocument.groupNodes( ...
        before, before.selection, "");
    document.selection = groupId;
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.objectediting.group.rejected", ...
        state.session.workflow.status);
    return;
end
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Group objects");
end
