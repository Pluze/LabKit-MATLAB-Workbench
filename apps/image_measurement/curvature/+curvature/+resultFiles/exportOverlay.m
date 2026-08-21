% App-owned implementation for curvature.resultFiles.exportOverlay within the curvature product workflow.
function applicationState = exportOverlay( ...
        applicationState, callbackContext)
%EXPORTOVERLAY Write the shared preview model.
if isempty(applicationState.session.cache.image)
    callbackContext.alert( ...
        "Open an image before exporting an overlay.", "No image loaded");
    return
end
choice = callbackContext.chooseOutputFile( ...
    ["*.png", "PNG image (*.png)"], ...
    defaultOutputPath(applicationState, "curvature_overlay.png"));
if choice.Cancelled
    callbackContext.log("info", ...
        "curvature.resultfiles.exportoverlay.cancelled", ...
        "Overlay PNG export cancelled.");
    return
end
filepath = string(choice.Value);
project = applicationState.project;
try
    model = curvature.curvePreview.model( ...
        applicationState.session.cache.image, ...
        project.annotations.curvePoints, project.results.fit, ...
        project.parameters.showDensePoints, ...
        applicationState.session.view.scaleBar);
    curvature.resultFiles.writeOverlayPng(model, filepath);
catch ME
    callbackContext.log("error", "curvature.resultfiles.exportoverlay.exception", "Export Curvature overlay PNG", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not export overlay PNG");
    return
end
applicationState.project.results.lastOverlayExport = struct( ...
    "pngPath", filepath, "outputPath", filepath);
callbackContext.log("info", ...
    "curvature.resultfiles.exportoverlay.completed", ...
    "Exported the overlay PNG.");
end

function filepath = defaultOutputPath(applicationState, filename)
folder = string(fileparts(applicationState.session.cache.imagePath));
if strlength(folder) == 0 || ~isfolder(folder)
    folder = string(pwd);
end
filepath = string(fullfile(folder, filename));
end
