function state = resetStyle(state, callbackContext)
before = state.session.editor.document;
document = before;
property = state.session.editor.activeProperty;
try
    targets = cascadeTargets(document, state.session.editor.activeScope);
    for k = 1:size(targets, 1)
        document = figure_studio.figureDocument.clearStyle( ...
            document, targets(k, 1), targets(k, 2), property);
    end
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.objectediting.reset.rejected", ...
        state.session.workflow.status);
    return;
end
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Reset " + property);
end

function targets = cascadeTargets(document, scope)
selected = document.nodes(ismember(string({document.nodes.id}), ...
    document.selection));
scope = lower(string(scope));
if scope == "selection"
    targets = [repmat("object", numel(selected), 1), string({selected.id}).'];
elseif scope == "type"
    values = unique(string({selected.kind}));
    values(values == "group") = [];
    targets = [repmat("kind", numel(values), 1), values(:)];
elseif scope == "role"
    values = unique(string({selected.role}));
    targets = [repmat("role", numel(values), 1), values(:)];
elseif scope == "group"
    values = unique([string({selected.groupId}), ...
        string({selected(string({selected.kind}) == "group").id})]);
    values(values == "") = [];
    targets = [repmat("group", numel(values), 1), values(:)];
else
    targets = ["document", "*"];
end
if isempty(targets)
    error("figure_studio:objectEditing:NoStyleTarget", ...
        "Select an object or group for this style scope.");
end
end
