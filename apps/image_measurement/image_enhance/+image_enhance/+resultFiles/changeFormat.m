% App-owned implementation for image_enhance.resultFiles.changeFormat within the image_enhance product workflow.
function applicationState = changeFormat( ...
        applicationState, format, callbackContext)
%CHANGEFORMAT Select the batch image format and invalidate prior export.
format = upper(string(format));
if ~isscalar(format) || ~any(format == ["PNG" "TIFF" "JPEG"])
    callbackContext.log("warning", ...
        "image_enhance.resultfiles.changeformat.ignored", ...
        "Ignored an unsupported export format.");
    return;
end
applicationState.project.parameters.exportFormat = format;
applicationState = ...
    image_enhance.enhancementPipeline.invalidateResults(applicationState);
end
