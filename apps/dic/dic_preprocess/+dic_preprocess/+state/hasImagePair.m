% Expected caller: DIC preprocess runner and direct unit tests. Input is the app
% state. Output is true when both current image slots are populated. Side
% effects: none.

function tf = hasImagePair(S)
%HASIMAGEPAIR Return whether the DIC preprocess current pair is loaded.

    tf = ~isempty(S.currentReferenceImage) && ~isempty(S.currentMovingImage);
end
