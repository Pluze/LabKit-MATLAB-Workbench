% App-owned implementation for batch_crop.resultFiles.settingsChanged within the batch_crop product workflow.
function applicationState = settingsChanged(applicationState, ~, ~)
applicationState.project.results = ...
    batch_crop.resultFiles.clearExportState(applicationState.project.results);
end
