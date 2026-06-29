% Expected caller: Image Enhance runner. Input is app state. Output is the
% active shared or per-image pending-preview dirty flag.
function tf = activePendingDirty(S)
    if S.batchMode || isempty(S.items)
        tf = S.pendingDirty;
    else
        tf = S.items(S.currentIndex).pendingDirty;
    end
end
