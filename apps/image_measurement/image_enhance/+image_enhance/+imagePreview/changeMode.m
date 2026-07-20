function applicationState = changeMode( ...
        applicationState, mode, callbackContext)
%CHANGEMODE Select the original, enhanced, or before/after preview.
mode = string(mode);
if isscalar(mode) && ...
        any(mode == ["Enhanced" "Original" "Before | After"])
    applicationState.session.view.previewMode = mode;
    applicationState.session.view.roiEditing = false;
else
    callbackContext.appendStatus( ...
        "Ignored an unsupported image preview mode.");
end
end
