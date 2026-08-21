% App-owned implementation for dic_preprocess.resultFiles.saveMask within the dic_preprocess product workflow.
function applicationState = saveMask(applicationState, callbackContext)
%SAVEMASK Write the current ROI mask.
mask = applicationState.project.annotations.maskImage;
if isempty(mask)
    [mask, accepted] = ...
        dic_preprocess.maskEditing.currentBoundaryMask(applicationState);
    if ~accepted
        callbackContext.alert( ...
            "Draw a mask ROI or add a boundary before saving.", ...
            "Save ROI mask");
        return
    end
    applicationState.project.annotations.maskImage = mask;
end
choice = callbackContext.chooseOutputFile( ...
    ["*.png", "PNG mask"], "roi_mask.png");
if choice.Cancelled
    callbackContext.log("info", "dic_preprocess.resultfiles.savemask.status", "Save ROI mask cancelled.");
    return
end
filepath = string(choice.Value);
dic_preprocess.resultFiles.writeMask(mask, filepath);
applicationState.project.results.maskOutputPath = filepath;
callbackContext.log("info", "dic_preprocess.resultfiles.savemask.status", ...
    "Saved the ROI mask.");
end
