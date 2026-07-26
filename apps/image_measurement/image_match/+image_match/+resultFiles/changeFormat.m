% App-owned implementation for image_match.resultFiles.changeFormat within the image_match product workflow.
function applicationState = changeFormat( ...
        applicationState, format, callbackContext)
%CHANGEFORMAT Select the matched-image batch format.
format = upper(string(format));
if ~isscalar(format) || ~any(format == ["PNG" "TIFF" "JPEG"])
    callbackContext.log("warning", ...
        "image_match.resultfiles.changeformat.ignored", ...
        "Ignored an unsupported export format.");
    return;
end
applicationState.project.parameters.exportFormat = format;
applicationState = ...
    image_match.matchPipeline.invalidateResults(applicationState);
end
