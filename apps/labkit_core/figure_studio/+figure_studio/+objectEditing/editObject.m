%EDITOBJECT Apply layer-table visibility, locking, role, name, and grouping.
function state = editObject(state, edit, callbackContext)
arguments
    state (1, 1) struct
    edit (1, 1) labkit.app.event.TableCellEdit
    callbackContext (1, 1) labkit.app.CallbackContext
end
if edit.RowIndex > numel(state.session.editor.document.nodes), return; end
before = state.session.editor.document;
document = before;
node = document.nodes(edit.RowIndex);
try
    switch edit.ColumnIndex
        case 1
            node.visible = logicalValue(edit.NewValue);
        case 2
            node.locked = logicalValue(edit.NewValue);
        case 3
            node.legendVisible = logicalValue(edit.NewValue);
        case 5
            node.role = requiredText(edit.NewValue, "Role");
        case 6
            node.name = requiredText(edit.NewValue, "Name");
        case 7
            node.groupId = string(edit.NewValue);
            node.parentId = node.groupId;
    end
catch exception
    state.session.workflow.status = string(exception.message);
    callbackContext.log("info", "figure_studio.objectediting.edit.rejected", ...
        state.session.workflow.status);
    return;
end
document.nodes(edit.RowIndex) = node;
state = figure_studio.axisEditing.commitDocument( ...
    state, before, document, "Edit object");
end

function value = logicalValue(value)
if islogical(value) && isscalar(value), return; end
value = lower(strtrim(string(value)));
if any(value == ["true", "on", "yes", "1"]), value = true;
elseif any(value == ["false", "off", "no", "0"]), value = false;
else
    error("figure_studio:objectEditing:InvalidLogical", ...
        "Show, lock, and legend values must be true or false.");
end
end

function value = requiredText(value, label)
value = strtrim(string(value));
if ~isscalar(value) || strlength(value) == 0
    error("figure_studio:objectEditing:InvalidText", ...
        "%s must be nonempty text.", label);
end
end
