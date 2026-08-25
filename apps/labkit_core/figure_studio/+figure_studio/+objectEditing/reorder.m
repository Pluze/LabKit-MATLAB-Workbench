function state = reorder(state, direction, callbackContext)
before = state.session.editor.document;
try
    document = figure_studio.figureDocument.reorderNodes( ...
        before, expandedSelection(before), direction);
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.objectediting.reorder.rejected", ...
        state.session.workflow.status);
    return;
end
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Move objects " + string(direction));
end

function ids = expandedSelection(document)
ids = string(document.selection(:));
groupIds = ids(ismember(ids, string({document.nodes( ...
    string({document.nodes.kind}) == "group").id})));
members = string({document.nodes(ismember( ...
    string({document.nodes.groupId}), groupIds)).id}).';
ids = [ids; members];
ids = unique(ids(ismember(ids, string({document.nodes.id}))));
end
