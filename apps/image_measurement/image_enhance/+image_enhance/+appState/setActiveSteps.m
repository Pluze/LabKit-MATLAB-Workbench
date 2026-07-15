% Expected caller: Image Enhance runner. Inputs are app state and a step
% vector. Output is state with shared or current-image history updated.
function S = setActiveSteps(S, steps)
    if S.project.parameters.batchMode || isempty(S.project.annotations.items)
        S.project.annotations.sharedSteps = steps;
    else
        index = S.session.selection.currentIndex;
        S.project.annotations.items(index).steps = steps;
    end
end
