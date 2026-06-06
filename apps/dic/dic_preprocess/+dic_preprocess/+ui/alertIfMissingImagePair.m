% Expected caller: DIC preprocess runner. Inputs are figure, state, alert
% message, and alert title. Output is true when an alert was shown. Side effect:
% shows a user alert only when the current image pair is missing.

function shown = alertIfMissingImagePair(fig, S, messageText, titleText)
%ALERTIFMISSINGIMAGEPAIR Alert when DIC preprocess lacks a current image pair.

    shown = ~dic_preprocess.state.hasImagePair(S);
    if shown
        uialert(fig, messageText, titleText);
    end
end
