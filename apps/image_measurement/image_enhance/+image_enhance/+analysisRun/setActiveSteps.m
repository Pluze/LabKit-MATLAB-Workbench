% Replace the shared or selected per-image enhancement history in App state.
function state = setActiveSteps(state, steps)
    if state.project.parameters.batchMode || ...
            isempty(state.project.annotations.items)
        state.project.annotations.sharedSteps = steps;
    else
        index = state.session.selection.currentIndex;
        state.project.annotations.items(index).steps = steps;
    end
end
