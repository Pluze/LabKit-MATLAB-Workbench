function applicationState = export(applicationState, context)
%EXPORT Write synchronized NI-DMM CSV and complete MAT outputs.
buffer = context.getResource("nidmmBuffer");
valid = buffer("valid");
if ~any(valid)
    context.alert("No valid NI-DMM samples are available.", ...
        "Export NI-DMM Recording");
    return;
end
choice = context.chooseOutputFile(["*.csv", "CSV files"], ...
    "ni_dmm_recording.csv");
if choice.Cancelled
    return;
end
csvPath = string(choice.Value);
[folder, stem, extension] = fileparts(csvPath);
if lower(string(extension)) ~= ".csv"
    csvPath = string(fullfile(folder, string(stem) + ".csv"));
end
timestampUTC = buffer("timestampUTC");
elapsed_s = buffer("elapsed_s");
measurement = buffer("value");
timeUncertainty_s = buffer("timeUncertainty_s");
configuration = buffer("configuration");
unit = repmat(configuration.Unit, sum(valid), 1);
mode = repmat(configuration.Mode, sum(valid), 1);
output = table(timestampUTC(valid), elapsed_s(valid), measurement(valid), ...
    unit, mode, timeUncertainty_s(valid), 'VariableNames', ...
    {'TimestampUTC', 'Elapsed_s', 'Measurement', 'Unit', 'Mode', ...
    'TimeUncertainty_s'});
writetable(output, csvPath);
recording = struct("TimestampUTC", timestampUTC, ...
    "ReceivedAtUTC", buffer("receivedAtUTC"), ...
    "Elapsed_s", elapsed_s, "Measurement", measurement, ...
    "Valid", valid, "TimeUncertainty_s", timeUncertainty_s, ...
    "Configuration", configuration, ...
    "RequestedRate", applicationState.session.configuration.rate, ...
    "StartedAtUTC", buffer("startedAtUTC"));
matPath = string(fullfile(folder, string(stem) + ".mat"));
save(matPath, "recording");
applicationState.session.export.status = "Exported: " + csvPath;
end
