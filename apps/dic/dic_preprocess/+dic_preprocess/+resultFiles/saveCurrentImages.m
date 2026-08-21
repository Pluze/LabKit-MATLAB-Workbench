% App-owned implementation for dic_preprocess.resultFiles.saveCurrentImages within the dic_preprocess product workflow.
function applicationState = saveCurrentImages( ...
        applicationState, callbackContext)
%SAVECURRENTIMAGES Write the working reference and moving pair.
cache = applicationState.session.cache;
if isempty(cache.currentReferenceImage) || isempty(cache.currentMovingImage)
    callbackContext.alert( ...
        "Load both images before saving the current pair.", ...
        "Missing images");
    return
end
choice = callbackContext.chooseOutputFolder("");
if choice.Cancelled
    callbackContext.log("info", "dic_preprocess.resultfiles.savecurrentimages.status", "Save current images cancelled.");
    return
end
folder = string(choice.Value);
outputs = dic_preprocess.resultFiles.writeCurrentImages( ...
    cache.currentReferenceImage, cache.currentMovingImage, folder);
applicationState.project.results.currentImagesOutputPath = ...
    outputs.referencePath;
callbackContext.log("info", "dic_preprocess.resultfiles.savecurrentimages.status", "Saved current DIC image pair.");
end
