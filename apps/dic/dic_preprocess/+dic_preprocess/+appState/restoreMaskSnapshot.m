% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% current app state and one mask-history snapshot. Output restores mask canvas
% and anchor fields. Side effects: none.

function S = restoreMaskSnapshot(S, snapshot)
%RESTOREMASKSNAPSHOT Restore a DIC preprocess mask-edit undo snapshot.

    S.maskImage = snapshot.maskImage;
    S.maskPoints = snapshot.maskPoints;
end
