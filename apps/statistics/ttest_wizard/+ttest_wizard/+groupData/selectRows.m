function state = selectRows(state, selection, context)
%SELECTROWS Remember editable analysis-table cells selected by the user.
%
% Expected caller: dataTable OnCellSelectionChanged. This transition stores
% only the typed cell coordinates used by later assign and delete actions.

arguments
    state (1, 1) struct
    selection (1, 1) labkit.app.event.TableCellSelection
    context (1, 1) labkit.app.CallbackContext
end

state.session.selection.analysisCells = double(selection.CellIndices);
end
