% Expected caller: Image Enhance export callback. Input is app state. Output
% is the shared history or a concatenated snapshot of per-image histories.
function steps = stepsForTask(S)
    if S.batchMode
        steps = S.steps;
    else
        steps = vertcat(S.items.steps);
    end
end
