function view = present(state)
%PRESENT Compose the complete transient Mark-10 monitor view.
s = state.session;
connected = s.connection.connected;
ports = s.connection.ports;
if isempty(ports), ports = "No ports"; end
model = struct("time_s", s.acquisition.plotTime_s, ...
    "force_N", s.acquisition.plotForce_N, ...
    "travel_mm", s.acquisition.plotTravel_mm, ...
    "limits", s.cache.plotLimits, "fitViewport", true);
analysisModel = struct( ...
    "strain_percent", s.analysis.plotStrain_percent, ...
    "stress_MPa", s.analysis.plotStress_MPa, ...
    "fitLines", s.analysis.fitLines, "summary", s.analysis.summary);
view = labkit.app.view.Snapshot();
view = view.choices("serialPort", ports);
view = view.value("serialPort", selectedPort(s.connection.selectedPort, ports));
view = view.value("sampleRate", s.acquisition.rate);
view = view.value("experimentType", s.experiment.type);
view = view.value("gaugeUnit", displaySetting("unit", s.settingsDraft.unit));
view = view.value("gaugeMode", displaySetting("mode", s.settingsDraft.mode));
view = view.value("currentFilter", ...
    displaySetting("currentFilter", s.settingsDraft.currentFilter));
view = view.value("displayFilter", ...
    displaySetting("displayFilter", s.settingsDraft.displayFilter));
view = view.value("outputFormat", ...
    displaySetting("outputFormat", s.settingsDraft.outputFormat));
view = view.value("autoOutput", ...
    displaySetting("autoOutput", s.settingsDraft.autoOutput));
view = view.value("analysisForceZero", ...
    analysisValue(s.analysis, "forceZeroDraft_N", ...
    analysisValue(s.analysis, "forceZero_N", 0)));
view = view.value("analysisTravelZero", ...
    analysisValue(s.analysis, "travelZeroDraft_mm", ...
    analysisValue(s.analysis, "travelZero_mm", 0)));
view = view.value("gaugeLength", s.analysis.gaugeLength_mm);
view = view.value("specimenWidth", s.analysis.width_mm);
view = view.value("specimenThickness", s.analysis.thickness_mm);
view = view.value("geometryConfirmed", s.analysis.geometryConfirmed);
view = view.value("fitMode", s.analysis.fitMode);
view = view.value("manualFitStart", s.analysis.manualStart_mm);
view = view.value("manualFitEnd", s.analysis.manualEnd_mm);
view = view.text("connectionStatus", s.connection.status);
readout = compose("Force: %s N\nTravel: %s mm", ...
    displayNumber(s.acquisition.force_N), ...
    displayNumber(s.acquisition.travel_mm));
view = view.text("liveReadout", readout);
view = view.text("acquisitionStatus", acquisitionText(s.acquisition));
view = view.text("exportStatus", s.export.status);
view = view.text("playbackStatus", s.playback.status);
view = view.text("appliedZeroStatus", compose( ...
    "Force %.6g N | Travel %.6g mm", ...
    analysisValue(s.analysis, "forceZero_N", 0), ...
    analysisValue(s.analysis, "travelZero_mm", 0)));
view = view.text("analysisStatus", s.analysis.status);
view = view.text("analysisExportStatus", s.analysis.exportStatus);
view = view.text("settingsStatus", settingsText(s.settings));
view = view.text("deviceIdentity", s.connection.identity);
view = view.text("deviceCapabilities", s.connection.capabilities);
view = view.text("lastFailure", blankFallback(s.connection.lastFailure));
view = view.enabled("refreshPorts", ~connected);
view = view.enabled("connectDevice", ...
    ~connected && any(ports ~= "No ports"));
view = view.enabled("disconnectDevice", connected);
view = view.enabled("startRecording", ...
    connected && ~s.acquisition.recording);
view = view.enabled("stopRecording", ...
    connected && s.acquisition.recording);
view = view.enabled("zeroForce", connected);
view = view.enabled("zeroTravel", connected);
view = view.enabled("refitLiveAxes", ...
    ~isempty(s.acquisition.plotTime_s));
view = view.enabled("refreshSettings", connected);
view = view.enabled("applySettings", connected);
view = view.enabled("exportRecording", ...
    s.acquisition.recordedValidCount > 0);
view = view.enabled("openRecording", ...
    ~connected && ~s.playback.playing);
view = view.enabled("resetRecording", ...
    ~connected && s.playback.loaded);
view = view.enabled("playRecording", ...
    ~connected && s.playback.loaded && ~s.playback.playing);
view = view.enabled("pauseRecording", ...
    ~connected && s.playback.loaded && ...
    s.playback.cursor < s.playback.count);
view = view.enabled("refitReplayAxes", ...
    ~isempty(s.acquisition.plotTime_s));
view = view.enabled("runModulusAnalysis", analysisDataAvailable(s));
view = view.enabled("exportModulusResults", ...
    ~isempty(s.analysis.resultRows));
view = view.tableData("recentData", recentTable(s.acquisition), ...
    Columns=["Time_s", "Force_N", "Travel_mm"]);
view = view.tableData("modulusResults", s.analysis.resultRows, ...
    Columns=["Seg.", "Phase", "Start s", "End s", ...
    "Fit from mm", "Fit to mm", "n", "k N/mm", ...
    "E MPa", "R²", "Status"]);
view = view.renderPlot("livePlots", model, ...
    ViewRevision=s.cache.plotViewRevision);
view = view.renderPlot("modulusPlot", analysisModel, ...
    ViewRevision=analysisRevision(s.analysis));
end

function value = analysisRevision(analysis)
value = 0;
if isfield(analysis, "resultRevision")
    value = analysis.resultRevision;
end
end

function value = analysisValue(analysis, name, fallback)
value = fallback;
if isfield(analysis, name)
    value = analysis.(name);
end
end

function tf = analysisDataAvailable(s)
source = "Live Recording";
if isfield(s.analysis, "dataSource")
    source = string(s.analysis.dataSource);
elseif s.playback.loaded
    source = "Loaded Recording";
end
tf = (source == "Loaded Recording" && s.playback.loaded) || ...
    (source == "Live Recording" && ...
    ~s.acquisition.recording && s.acquisition.recordedValidCount >= 16);
end

function value = recentTable(acquisition)
count = numel(acquisition.plotTime_s);
first = max(1, count - 199);
if count == 0
    value = table(zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        'VariableNames', {'Time_s', 'Force_N', 'Travel_mm'});
    return;
end
value = table(acquisition.plotTime_s(first:end), ...
    acquisition.plotForce_N(first:end), ...
    acquisition.plotTravel_mm(first:end), ...
    'VariableNames', {'Time_s', 'Force_N', 'Travel_mm'});
end

function value = selectedPort(value, ports)
if strlength(value) == 0, value = ports(1); end
end

function value = displaySetting(name, value)
value = mark10_monitor.settings.displayChoice(name, value);
end

function text = displayNumber(value)
if isfinite(value), text = compose("%.6g", value); else, text = "—"; end
end

function text = acquisitionText(value)
mode = ternary(value.recording, "recording", "monitoring");
text = compose("%s | samples %d (%d valid, %d invalid) | %.2f Hz", ...
    mode, value.sampleCount, value.validCount, value.invalidCount, ...
    value.actualRate_Hz);
end

function text = settingsText(value)
if strlength(value.raw) == 0
    text = "Settings not read.";
else
    text = compose("%s | %s | FLTC %g | FLTP %g | %s | AOUT %g", ...
        value.unit, value.mode, value.currentFilter, value.displayFilter, ...
        value.outputFormat, value.autoOutput);
end
end

function value = blankFallback(value)
if strlength(value) == 0, value = "None"; end
end

function value = ternary(condition, whenTrue, whenFalse)
if condition, value = whenTrue; else, value = whenFalse; end
end
