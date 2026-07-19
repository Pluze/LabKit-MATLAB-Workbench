function state = selectConnection(state, selection, ~)
%SELECTCONNECTION Store the selected connection row.
state.session.selection.selectedEdgeIndex = 0;
if ~isempty(selection.CellIndices)
    state.session.selection.selectedEdgeIndex = selection.CellIndices(1, 1);
end
end
