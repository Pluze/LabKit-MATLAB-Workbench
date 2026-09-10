function view = present(applicationState)
%PRESENT Compose the complete NI DMM Recorder snapshot.
s = applicationState.session;
connected = s.connection.connected;
recording = s.acquisition.recording;
unit = s.acquisition.unit;
if strlength(unit) == 0
    unit = "—";
end
valueText = "—";
if isfinite(s.acquisition.value)
    valueText = compose("%.9g", s.acquisition.value);
end
view = labkit.app.view.Snapshot();
resources = string({s.connection.devices.Resource});
if isempty(resources)
    resources = "No devices found";
    selectedResource = resources;
else
    selectedResource = s.connection.resource;
end
view = view.choices("resourceName", resources);
view = view.value("resourceName", selectedResource);
view = view.value("measurementMode", s.configuration.mode);
view = view.value("rangeMode", s.configuration.rangeMode);
view = view.value("fixedRange", s.configuration.fixedRange);
view = view.value("resolutionDigits", s.configuration.digits);
view = view.value("sampleRate", s.configuration.rate);
view = view.text("connectionStatus", s.connection.status);
view = view.text("deviceIdentity", s.connection.device);
view = view.text("lastFailure", blankFallback(s.connection.lastFailure));
view = view.text("liveReadout", "Value: " + valueText + " " + unit);
view = view.text("recordingStatus", compose( ...
    "%s | samples %d (%d valid, %d invalid) | %.2f Hz", ...
    recordingLabel(recording), s.acquisition.sampleCount, ...
    s.acquisition.validCount, s.acquisition.invalidCount, ...
    s.acquisition.actualRate_Hz));
view = view.text("exportStatus", s.export.status);
view = view.enabled("refreshDevices", ~connected);
view = view.enabled("connectDevice", s.connection.available && ...
    ~isempty(s.connection.devices) && ~connected);
view = view.enabled("disconnectDevice", connected);
view = view.enabled("resourceName", ~connected);
for id = ["measurementMode", "rangeMode", "resolutionDigits", "sampleRate"]
    view = view.enabled(id, ~recording);
end
view = view.enabled("fixedRange", ~recording && ...
    s.configuration.rangeMode == "Fixed");
view = view.enabled("readOnce", connected && ~recording);
view = view.enabled("startRecording", connected && ~recording);
view = view.enabled("stopRecording", recording);
view = view.enabled("refitPlot", ~isempty(s.acquisition.plotTime_s));
view = view.enabled("exportRecording", ...
    ~recording && s.acquisition.validCount > 0);
recent = recentTable(s.acquisition, recording);
view = view.tableData("recentData", recent, ...
    Columns=["TimestampUTC", "Elapsed_s", "Measurement", "Unit"]);
model = struct("Time_s", s.acquisition.plotTime_s, ...
    "Value", s.acquisition.plotValue, "Unit", unit);
view = view.renderPlot("measurementPlot", model, ...
    ViewRevision=s.cache.plotRevision);
end

function value = recentTable(acquisition, recording)
if recording || isempty(acquisition.plotTime_s)
    value = table(NaT(0, 1, "TimeZone", "UTC"), zeros(0, 1), ...
        zeros(0, 1), strings(0, 1), 'VariableNames', ...
        {'TimestampUTC', 'Elapsed_s', 'Measurement', 'Unit'});
    return;
end
count = numel(acquisition.plotTime_s);
first = max(1, count - 199);
% Buffer implementations may retain vectors in either orientation. Tables
% require every variable to agree on row count after recording stops.
elapsed = acquisition.plotTime_s(first:end).';
measurement = acquisition.plotValue(first:end).';
timestamp = acquisition.plotTimestampUTC(first:end).';
elapsed = elapsed(:);
measurement = measurement(:);
timestamp = timestamp(:);
unit = repmat(string(acquisition.unit), numel(elapsed), 1);
value = table(timestamp, elapsed, measurement, unit, 'VariableNames', ...
    {'TimestampUTC', 'Elapsed_s', 'Measurement', 'Unit'});
end

function value = recordingLabel(recording)
if recording
    value = "recording";
else
    value = "stopped";
end
end

function value = blankFallback(value)
if strlength(value) == 0
    value = "None";
end
end
