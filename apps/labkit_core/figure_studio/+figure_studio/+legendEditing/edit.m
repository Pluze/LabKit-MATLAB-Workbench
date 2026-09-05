function applicationState = edit(applicationState, editValue, callbackContext)
%EDIT Commit one legend label, ordering, or inclusion edit as an undoable edit.
% Native table callback uses current panel rows and leaves all source arrays intact.
editor = applicationState.session.editor;
rows = figure_studio.legendEditing.rows(editor.document, editor.activePanelId);
row = editValue.RowIndex;
if row < 1 || row > numel(rows), return; end
try
    switch editValue.ColumnIndex
        case 2
            label = strip(string(editValue.NewValue));
            if ~isscalar(label) || ismissing(label) || strlength(label) == 0
                error("figure_studio:legendEditing:InvalidName", ...
                    "Legend names must be nonempty; uncheck Show to omit a row.");
            end
            rows(row).label = label;
        case 3
            position = str2double(string(editValue.NewValue));
            if ~isscalar(position) || ~isfinite(position) || position ~= fix(position) || ...
                    position < 1 || position > numel(rows)
                error("figure_studio:legendEditing:InvalidPosition", ...
                    "Position must be an integer between 1 and the number of rows.");
            end
            moving = rows(row);
            rows(row) = [];
            rows = [rows(1:position-1); moving; rows(position:end)];
        case 4
            if ~islogical(editValue.NewValue) || ~isscalar(editValue.NewValue)
                error("figure_studio:legendEditing:InvalidVisibility", "Show must be a checkbox value.");
            end
            rows(row).enabled = editValue.NewValue;
        otherwise
            return;
    end
catch cause
    callbackContext.log("warning", "figure_studio.legend_edit_rejected", ...
        "Legend edit was rejected.", Exception=cause);
    callbackContext.alert(cause.message, "Edit legend");
    return;
end
document = figure_studio.legendEditing.replaceRows(editor.document, editor.activePanelId, rows);
applicationState = figure_studio.axisEditing.commitDocument( ...
    applicationState, editor.document, document, "Edit legend");
end
