% App-owned implementation for gait_analysis.stepPreview.select within the gait_analysis product workflow.
function applicationState = select( ...
        applicationState, selection, callbackContext)
%SELECT Use the selected result-table row as the active gait step.
arguments
    applicationState (1, 1) struct
    selection (1, 1) labkit.app.event.TableCellSelection
    callbackContext (1, 1) labkit.app.CallbackContext
end
if isempty(selection.CellIndices)
    return
end
applicationState.session.selection.currentStepIndex = ...
    gait_analysis.stepPreview.boundedIndex( ...
        applicationState, selection.CellIndices(1, 1));
end
