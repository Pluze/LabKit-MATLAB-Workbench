function applicationState = settingsChanged(applicationState, ~, ~)
    applicationState.session.result = [];
    applicationState.session.analysisStatus = "Select Analyze EMG to apply the marked windows.";
end
