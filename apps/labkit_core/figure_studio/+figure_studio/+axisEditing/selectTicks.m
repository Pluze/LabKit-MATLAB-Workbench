function state = selectTicks(state, selection, ~)
arguments
    state (1, 1) struct
    selection (1, 1) labkit.app.event.TableCellSelection
    ~
end
state.session.editor.selectedTickRows = unique(selection.CellIndices(:, 1));
end
