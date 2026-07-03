% Expected caller: Image Enhance runner. Inputs are the app state struct.
% Output is the active shared or per-image enhancement history.
function steps = activeSteps(S)
    if S.batchMode || isempty(S.items)
        steps = S.steps;
    else
        steps = S.items(S.currentIndex).steps;
    end
end
