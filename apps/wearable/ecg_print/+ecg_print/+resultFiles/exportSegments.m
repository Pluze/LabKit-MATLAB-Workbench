function applicationState = exportSegments(applicationState,callbackContext)
%EXPORTSEGMENTS Export the exact per-beat table displayed by the App.
result=applicationState.session.cache.ecgNext;
if isempty(result)||~result.ok
    callbackContext.alert("Analyze ECG before exporting.","No analysis result");return;
end
chosen=callbackContext.chooseOutputFile(["*.csv","CSV files (*.csv)"],"ecg_beats.csv");
if chosen.Cancelled,return;end
writetable(result.perBeat,string(chosen.Value));
callbackContext.log("info","ecg_print.resultfiles.beats.completed", ...
    "Exported the ECGNExT per-beat table.",Attributes=struct('beatCount',height(result.perBeat)));
end
