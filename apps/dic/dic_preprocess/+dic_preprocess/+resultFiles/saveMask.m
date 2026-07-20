% App-owned implementation for dic_preprocess.resultFiles.saveMask within the dic_preprocess product workflow.
function applicationState = saveMask(applicationState, callbackContext)
%SAVEMASK Write the current ROI mask and result manifest.
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
    callbackContext.appendStatus("Save ROI mask cancelled.");
    return
end
filepath = string(choice.Value);
dic_preprocess.resultFiles.writeMask(mask, filepath);
[folder, name, extension] = fileparts(filepath);
output = labkit.app.result.File("roiMask", "primary", ...
    string(name) + string(extension), MediaType="image/png");
package = labkit.app.result.Package(Outputs={output}, ...
    Inputs=struct("sources", applicationState.project.inputs.sources), ...
    Parameters=applicationState.project.parameters, ...
    Summary=struct("anchorCount", size( ...
        applicationState.project.annotations.maskPoints, 1)), ...
    ManifestName=string(name) + ".labkit.json");
written = callbackContext.writeResultPackage(folder, package);
applicationState.project.results.maskManifestPath = string(written.Value);
callbackContext.appendStatus("Saved ROI mask: " + filepath);
end
