% Return the shared or selected per-image enhancement history from App state.
function steps = activeSteps(state)
    if state.project.parameters.batchMode || ...
            isempty(state.project.annotations.items)
        steps = state.project.annotations.sharedSteps;
    else
        index = state.session.selection.currentIndex;
        steps = state.project.annotations.items(index).steps;
    end
end
