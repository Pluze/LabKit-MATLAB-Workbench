function applicationState = changeMode( ...
        applicationState, previewMode, callbackContext)
%CHANGEMODE Store the selected preview mode declared by the plot area.
previewMode = string(previewMode);
if isscalar(previewMode) && ...
        any(previewMode == ["Matched" "Original" "Before | After"])
    applicationState.session.view.previewMode = previewMode;
else
    callbackContext.appendStatus( ...
        "Ignored an unsupported image-match preview mode.");
end
end
