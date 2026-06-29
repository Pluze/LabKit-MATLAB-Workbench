% Expected caller: Image Enhance runner. Inputs are app state and logical
% value. Output is state with active dirty flag updated.
function S = setActivePendingDirty(S, value)
    if S.batchMode || isempty(S.items)
        S.pendingDirty = logical(value);
    else
        S.items(S.currentIndex).pendingDirty = logical(value);
    end
end
