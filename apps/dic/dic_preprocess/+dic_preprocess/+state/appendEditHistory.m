% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% current edit history, runner state, description, and optional max undo count.
% Outputs are the trimmed history and whether a snapshot was appended. Side
% effects: none.

function [history, appended] = appendEditHistory(history, S, description, maxUndoSteps)
%APPENDEDITHISTORY Append a DIC preprocess align/crop undo snapshot.

    if nargin < 4
        maxUndoSteps = 12;
    end
    appended = false;
    if isempty(S.currentReferenceImage) || isempty(S.currentMovingImage)
        return;
    end

    snapshot = struct( ...
        'reference', S.currentReferenceImage, ...
        'moving', S.currentMovingImage, ...
        'aligned', S.alignedImage, ...
        'cropReference', S.cropReference, ...
        'cropMoving', S.cropMoving, ...
        'maskImage', S.maskImage, ...
        'maskPoints', S.maskPoints, ...
        'description', description);
    history(end+1) = snapshot;
    if numel(history) > maxUndoSteps
        history = history((end - maxUndoSteps + 1):end);
    end
    appended = true;
end
