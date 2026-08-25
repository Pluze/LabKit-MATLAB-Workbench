function state = selectObjects(state, selection, ~)
arguments
    state (1, 1) struct
    selection (1, 1) labkit.app.event.TableCellSelection
    ~
end
rows = unique(selection.CellIndices(:, 1));
rows = rows(rows <= numel(state.session.editor.document.nodes));
state.session.editor.document.selection = string( ...
    {state.session.editor.document.nodes(rows).id}).';
end
