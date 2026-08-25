function state = duplicate(state, callbackContext)
before = state.session.editor.document;
try
    [document, ids] = figure_studio.figureDocument.duplicateNodes( ...
        before, expandedSelection(before));
    document.selection = ids;
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.objectediting.duplicate.rejected", ...
        state.session.workflow.status);
    return;
end
state.session.editor.nativePassThrough = false;
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Duplicate objects");
end

function ids = expandedSelection(document)
ids = string(document.selection(:));
groupIds = ids(ismember(ids, string({document.nodes( ...
    string({document.nodes.kind}) == "group").id})));
members = string({document.nodes(ismember( ...
    string({document.nodes.groupId}), groupIds)).id}).';
ids = [ids; members];
ids = unique(ids(ismember(ids, string({document.nodes.id}))));
ids = ids(~ismember(ids, string({document.nodes( ...
    string({document.nodes.kind}) == "group").id})));
end
