function applicationState = settingsChanged(applicationState, ~, ~)
applicationState.project.results = ...
    batch_crop.resultFiles.clearExportState(applicationState.project.results);
end
