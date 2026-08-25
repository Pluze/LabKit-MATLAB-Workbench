function state = ungroup(state, callbackContext)
before = state.session.editor.document;
selected = selectedMemberIds(before);
try
    document = figure_studio.figureDocument.ungroupNodes(before, selected);
    document.selection = selected;
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.objectediting.ungroup.rejected", ...
        state.session.workflow.status);
    return;
end
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Ungroup objects");
end

function ids = selectedMemberIds(document)
ids = string(document.selection(:));
selectedGroups = ids(ismember(ids, string({document.nodes( ...
    string({document.nodes.kind}) == "group").id})));
members = string({document.nodes(ismember( ...
    string({document.nodes.groupId}), selectedGroups)).id}).';
ids = [ids; members];
ids = unique(ids(ismember(ids, string({document.nodes.id}))));
ids = ids(~ismember(ids, selectedGroups));
end
