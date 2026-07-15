% Expected caller: Image Enhance runner. Inputs are the app state struct.
% Output is the active shared or per-image enhancement history.
function steps = activeSteps(S)
    if S.project.parameters.batchMode || isempty(S.project.annotations.items)
        steps = S.project.annotations.sharedSteps;
    else
        index = S.session.selection.currentIndex;
        steps = S.project.annotations.items(index).steps;
    end
end
