% Expected caller: Image Enhance runner. Inputs are app state and a step
% vector. Output is state with shared or current-image history updated.
function S = setActiveSteps(S, steps)
    if S.batchMode || isempty(S.items)
        S.steps = steps;
    else
        S.items(S.currentIndex).steps = steps;
    end
end
