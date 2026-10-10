function applicationState = exportStatistics(applicationState,callbackContext)
%EXPORTSTATISTICS Save per-beat mean, sample variance and counts.
result=applicationState.session.cache.ecgNext;
if isempty(result)||~result.ok
    callbackContext.alert("Analyze ECG before exporting.","No analysis result");return;
end
chosen=callbackContext.chooseOutputFile(["*.csv","CSV files (*.csv)"],"ecg_statistics.csv");
if chosen.Cancelled,return;end
writetable(result.statistics,string(chosen.Value));
callbackContext.log("info","ecg_print.resultfiles.statistics.completed", ...
    "Exported per-beat statistical summaries.");
end
