% Expected caller: Image Enhance runner. Input is app state. Output is the
% user-facing processing-mode summary.
function text = modeStatusText(S)
    if S.batchMode
        text = 'Batch mode: all images share the same parameters and history.';
    else
        text = 'Per-image mode: each image keeps its own parameters and history.';
    end
end
