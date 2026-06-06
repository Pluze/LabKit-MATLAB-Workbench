% Expected caller: DIC preprocess runner and direct unit tests. Input is the app
% state after align/crop/reset operations. Output clears mask outputs invalidated
% by image-pair changes. Side effects: none.

function S = clearOperationDerivedState(S)
%CLEAROPERATIONDERIVEDSTATE Clear DIC preprocess state derived from the pair.

    S.maskImage = [];
    S.maskPoints = [];
    S.maskHistory = S.maskHistory([]);
end
