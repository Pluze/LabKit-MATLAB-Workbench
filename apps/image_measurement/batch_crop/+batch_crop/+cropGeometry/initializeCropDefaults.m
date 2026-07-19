function applicationState = initializeCropDefaults(applicationState)
if applicationState.session.workflow.cropDefaultsInitialized || ...
        ~batch_crop.sourceFiles.hasCurrentImage(applicationState)
    return
end
imageData = batch_crop.sourceFiles.currentItem(applicationState).image;
% The established workflow starts with a crop spanning 70% of the source.
defaultCropFraction = 0.7;
applicationState.project.parameters.cropWidth = max(1, ...
    round(size(imageData, 2) * defaultCropFraction));
applicationState.project.parameters.cropHeight = max(1, ...
    round(size(imageData, 1) * defaultCropFraction));
applicationState.session.workflow.cropDefaultsInitialized = true;
end
