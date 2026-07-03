% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% current mask edit history, mask image, mask points, description, and optional
% max undo count. Output is the trimmed mask history. Side effects: none.

function history = appendMaskHistory(history, maskImage, maskPoints, description, maxUndoSteps)
%APPENDMASKHISTORY Append a DIC preprocess mask edit undo snapshot.

    if nargin < 5
        maxUndoSteps = 20;
    end
    snapshot = struct( ...
        'maskImage', maskImage, ...
        'maskPoints', maskPoints, ...
        'description', description);
    history(end+1) = snapshot;
    if numel(history) > maxUndoSteps
        history = history((end - maxUndoSteps + 1):end);
    end
end
