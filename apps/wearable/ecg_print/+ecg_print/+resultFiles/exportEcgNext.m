function applicationState = exportEcgNext(applicationState, callbackContext)
%EXPORTECGNEXT Save exact extraction and preparation provenance as a MAT file.
result = applicationState.session.cache.ecgNext;
if isempty(result) || ~result.ok
    callbackContext.alert("Analyze an eligible ECG ROI first.", "No ECGNExT result");
    return;
end
chosen = callbackContext.chooseOutputFile( ...
    ["*.mat", "MAT files (*.mat)"], "ecg_next_results.mat");
if chosen.Cancelled
    return;
end
ecgNext = result;
save(string(chosen.Value), 'ecgNext');
callbackContext.log("info", "ecg_print.resultfiles.ecgnext.completed", ...
    "Exported ECGNExT noise and preparation provenance.");
end
