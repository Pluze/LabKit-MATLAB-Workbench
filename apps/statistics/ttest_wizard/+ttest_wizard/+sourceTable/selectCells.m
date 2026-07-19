function state = selectCells(state, selection, context)
%SELECTCELLS Remember source-table cells and summarize numeric usability.
%
% Expected caller: sourceGrid OnCellSelectionChanged. Selection is the typed
% SDK payload; context is declared for the fixed callback contract but this
% transition performs no runtime side effect.

arguments
    state (1, 1) struct
    selection (1, 1) labkit.app.event.TableCellSelection
    context (1, 1) labkit.app.CallbackContext
end

indices = selection.CellIndices;
state.session.selection.sourceCells = double(indices);
source = state.session.cache.source;
if ~source.ok || isempty(indices)
    state.session.selection.selectionMessage = ...
        "Select numeric cells in the opened table.";
    return;
end
selected = ttest_wizard.sourceTable.extractNumericSelection( ...
    source.cells, indices);
state.session.selection.selectionMessage = selected.message;
end
