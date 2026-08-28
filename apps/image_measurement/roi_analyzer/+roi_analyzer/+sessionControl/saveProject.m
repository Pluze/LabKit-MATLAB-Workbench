function applicationState = saveProject(applicationState, callbackContext)
%SAVEPROJECT Save the current final task state to a chosen MAT file.
choice = callbackContext.chooseOutputFile( ...
    ["*.mat", "ROI Analyzer MAT project"], "roi-analyzer-project.mat");
if choice.Cancelled
    return
end
try
    roi_analyzer.archive.writeFile(applicationState, choice.Value);
catch ME
    callbackContext.log("error", ...
        "roi_analyzer.sessioncontrol.saveproject.exception", ...
        "Save ROI Analyzer project", Category="failure", ...
        Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not save project");
    return
end
callbackContext.log("info", ...
    "roi_analyzer.sessioncontrol.saveproject.completed", ...
    "Saved the current ROI Analyzer project.");
end
