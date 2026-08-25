function logPreviewRead(callbackContext, ok, message, eventName)
%LOGPREVIEWREAD Record a privacy-safe outcome for preview-refresh callbacks.
% Called by RHS Preview controls after readCurrentPreview. The original
% message may contain decoder or file details and remains in transient App
% state; this helper emits only the operation outcome to the session journal.
if strlength(string(message)) == 0
    return;
end
if ~ok
    callbackContext.log("error", eventName, "RHS preview read failed.");
end
end
