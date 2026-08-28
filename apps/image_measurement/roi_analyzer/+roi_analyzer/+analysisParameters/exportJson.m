function applicationState = exportJson(applicationState, callbackContext)
%EXPORTJSON Export current ROI geometry and analysis choices without results.
[annotation, sourceIndex] = ...
    roi_analyzer.roiLibrary.currentAnnotation(applicationState);
if sourceIndex < 1 || isempty(annotation.rois)
    callbackContext.alert("Create a ROI layout before exporting parameters.", ...
        "No ROI parameters");
    return
end
choice = callbackContext.chooseOutputFile( ...
    ["*.json", "ROI Analyzer parameter JSON"], ...
    "roi-analysis-parameters.json");
if choice.Cancelled
    return
end
try
    record = roi_analyzer.analysisParameters.buildRecord( ...
        applicationState.project, annotation);
    json = jsonencode(record, PrettyPrint=true);
    fileId = fopen(char(choice.Value), "w", "n", "UTF-8");
    if fileId < 0
        error("roi_analyzer:analysisParameters:WriteFailed", ...
            "Could not open the parameter JSON for writing.");
    end
    cleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, "%s\n", json);
    clear cleanup
catch ME
    callbackContext.log("error", ...
        "roi_analyzer.analysisparameters.exportjson.exception", ...
        "Export ROI analysis parameters", Category="failure", ...
        Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not export parameters");
    return
end
callbackContext.log("info", ...
    "roi_analyzer.analysisparameters.exportjson.completed", ...
    "Exported the current ROI analysis parameters.");
end
