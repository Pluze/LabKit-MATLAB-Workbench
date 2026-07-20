% App-owned implementation for batch_crop.resultFiles.present within the batch_crop product workflow.
function view = present(applicationState)
hasImage = batch_crop.sourceFiles.hasCurrentImage(applicationState);
view = labkit.app.view.Snapshot() ...
    .value("outputFolder", applicationState.project.parameters.outputFolder) ...
    .enabled("exportCrops", hasImage);
end
