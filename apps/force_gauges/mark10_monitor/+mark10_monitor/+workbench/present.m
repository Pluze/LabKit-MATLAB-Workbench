function view = present(state)
%PRESENT Compose the complete transient Mark-10 monitor view.
s = state.session;
filename = "";
if s.playback.loaded && s.analysis.dataSource == "Loaded Recording"
    [~, stem, extension] = fileparts(s.playback.source);
    filename = string(stem) + string(extension);
end
connected = s.connection.connected;
monitoring = acquisitionFlag(s.acquisition, "monitoring", connected);
ports = s.connection.ports;
if isempty(ports), ports = "No ports"; end
model = struct("time_s", s.acquisition.plotTime_s, ...
    "force_N", s.acquisition.plotForce_N, ...
    "travel_mm", s.acquisition.plotTravel_mm, ...
    "limits", s.cache.plotLimits, ...
    "limitRevision", s.cache.plotViewRevision, "filename", filename);
view = labkit.app.view.Snapshot().windowSubtitle(filename);
view = view.include(mark10_monitor.analysis.present(s.analysis,s.experiment.type,filename));
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
view = view.text("connectionStatus", s.connection.status);
readout = compose("Force: %s N\nTravel: %s mm", ...
    displayNumber(s.acquisition.force_N), ...
    displayNumber(s.acquisition.travel_mm));
view = view.text("liveReadout", readout);
view = view.text("acquisitionStatus", acquisitionText(s.acquisition));
view = view.text("exportStatus", s.export.status);
view = view.text("playbackStatus", s.playback.status);
view = view.text("settingsStatus", settingsText(s.settings));
view = view.text("deviceIdentity", s.connection.identity);
view = view.text("deviceCapabilities", s.connection.capabilities);
view = view.text("lastFailure", blankFallback(s.connection.lastFailure));
view = view.enabled("refreshPorts", ~connected);
view = view.enabled("connectDevice", ...
    ~connected && any(ports ~= "No ports"));
view = view.enabled("disconnectDevice", connected);
view = view.enabled("startMonitoring", connected && ~monitoring);
view = view.enabled("stopMonitoring", monitoring);
view = view.enabled("readOnce", connected && ~monitoring);
view = view.enabled("zeroForce", connected);
view = view.enabled("zeroTravel", connected);
view = view.enabled("refitLiveAxes", ...
    ~isempty(s.acquisition.plotTime_s));
view = view.enabled("refreshSettings", connected);
view = view.enabled("applySettings", connected);
view = view.enabled("exportRecording", ...
    ~monitoring && s.acquisition.retainedValidCount > 0);
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
view = view.enabled("exportStressStrain", s.analysis.curveReady);
view = view.enabled("updateStressStrain",analysisDataAvailable(s));
view = view.enabled("estimateInitialLength",analysisDataAvailable(s));
view = view.enabled("detectGlitches",analysisDataAvailable(s));
view = view.tableData("recentData", recentTable(s.acquisition, monitoring), ...
    Columns=["Time_s", "Force_N", "Travel_mm"]);
view = view.renderPlot("livePlots", model, ...
    ViewRevision=s.cache.plotViewRevision);

end

function tf = analysisDataAvailable(s)
source = "Live Monitoring";
if isfield(s.analysis, "dataSource")
    source = string(s.analysis.dataSource);
elseif s.playback.loaded
    source = "Loaded Recording";
end
tf = (source == "Loaded Recording" && s.playback.loaded) || ...
    (source == "Live Monitoring" && ...
    ~acquisitionFlag(s.acquisition, "monitoring", false) && ...
    s.acquisition.retainedValidCount >= 2);
end

function value = recentTable(acquisition, monitoring)
if monitoring
    % The native web table is intentionally a stopped-session consumer.
    % Replacing hundreds of cells during acquisition starves serial events;
    % the live readout and plots already own monitoring-time presentation.
    value = emptyRecentTable();
    return;
end
count = numel(acquisition.plotTime_s);
first = max(1, count - 199);
if count == 0
    value = emptyRecentTable();
    return;
end
value = table(acquisition.plotTime_s(first:end), ...
    acquisition.plotForce_N(first:end), ...
    acquisition.plotTravel_mm(first:end), ...
    'VariableNames', {'Time_s', 'Force_N', 'Travel_mm'});
end

function value = emptyRecentTable()
value = table(zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
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
if acquisitionFlag(value, "monitoring", false)
    mode = "monitoring";
else
    mode = "stopped";
end
text = compose("%s | samples %d (%d valid, %d invalid) | %.2f Hz", ...
    mode, value.sampleCount, value.validCount, value.invalidCount, ...
    value.actualRate_Hz);
end

function value = acquisitionFlag(acquisition, name, fallback)
value = fallback;
if isfield(acquisition, name)
    value = logical(acquisition.(name));
end
end

function text = settingsText(value)
if strlength(value.raw) == 0
    text = "Settings not read.";
else
    text = compose("%s | %s | FLTC %g | FLTP %g | %s | AOUT %g | IPOL%d", ...
        value.unit, value.mode, value.currentFilter, value.displayFilter, ...
        value.outputFormat, value.autoOutput, double(value.invertPolarity));
end
end

function value = blankFallback(value)
if strlength(value) == 0, value = "None"; end
end
