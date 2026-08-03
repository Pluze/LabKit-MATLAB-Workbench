% App-owned implementation for gait_analysis.stepPreview.select within the gait_analysis product workflow.
function applicationState = select( ...
        applicationState, selection, ~)
%SELECT Use the selected result-table row as the active gait step.
arguments
    applicationState (1, 1) struct
    selection (1, 1) labkit.app.event.TableCellSelection
    ~
end
if isempty(selection.CellIndices)
    return
end
previous = applicationState.session.selection.currentStepIndex;
selected = ...
    gait_analysis.stepPreview.boundedIndex( ...
        applicationState, selection.CellIndices(1, 1));
applicationState.session.selection.currentStepIndex = selected;
if selected ~= previous
    applicationState.session.cache.plotViewRevision = ...
        applicationState.session.cache.plotViewRevision + 1;
end
end
