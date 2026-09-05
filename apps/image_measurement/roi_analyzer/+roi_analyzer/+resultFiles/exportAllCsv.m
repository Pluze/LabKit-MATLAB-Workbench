function applicationState = exportAllCsv(applicationState, callbackContext)
%EXPORTALLCSV Export measured rows and explicit incomplete-image statuses.
project = applicationState.project;
if isempty(project.inputs.sources), return; end
choice = callbackContext.chooseOutputFile( ...
    ["*.csv", "CSV files (*.csv)"], fullfile(pwd, "roi_batch_measurements.csv"));
if choice.Cancelled, return; end
try
    output = roi_analyzer.resultFiles.buildBatchTable( ...
        project.inputs.sources, project.annotations.items, ...
        project.annotations.templates, project.results);
    writetable(output, string(choice.Value));
catch cause
    callbackContext.log("error", "roi_analyzer.batch.export_failed", ...
        "Could not export batch measurements.", Category="failure", ...
        Audience="developer", Exception=cause);
    callbackContext.alert(cause.message, "Could not export batch CSV");
    return
end
applicationState.project.results.lastExportPath = string(choice.Value);
callbackContext.log("info", "roi_analyzer.batch.exported", "Exported batch ROI measurements.");
end
