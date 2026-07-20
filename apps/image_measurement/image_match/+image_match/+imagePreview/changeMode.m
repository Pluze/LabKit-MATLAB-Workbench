% App-owned implementation for image_match.imagePreview.changeMode within the image_match product workflow.
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
