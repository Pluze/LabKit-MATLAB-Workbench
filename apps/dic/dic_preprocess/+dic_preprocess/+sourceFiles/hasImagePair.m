% Expected caller: DIC preprocess actions/presentation and unit tests.
% Input is the rebuildable session image cache; output reports a current pair.

function tf = hasImagePair(cache)
%HASIMAGEPAIR Return whether the DIC preprocess current pair is loaded.

    tf = ~isempty(cache.currentReferenceImage) && ...
        ~isempty(cache.currentMovingImage);
end
