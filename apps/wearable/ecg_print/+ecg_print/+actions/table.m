% App-owned action table for ECG Print. Expected caller is
% ecg_print.definition. Output maps semantic action ids to handlers used by
% labkit.ui.app.run. Handlers own recording import, analysis, exports, and
% debug sample setup.
function actions = table()
    actions = struct( ...
        "startup", @onStartup, ...
        "recordingChosen", @onRecordingChosen, ...
        "clearRecording", @onClearRecording, ...
        "previewHeader", @onPreviewHeader, ...
        "importOptionChanged", @onImportOptionChanged, ...
        "refreshImport", @onRefreshImport, ...
        "channelChanged", @onChannelChanged, ...
        "analyze", @onAnalyze, ...
        "exportSegments", @onExportSegments, ...
        "exportWaveform", @onExportWaveform, ...
        "refreshPlots", @onRefreshOnly);
end

function state = onStartup(state, ~, services)
    debugLog = services.debug;
    if ~isDebugEnabled(debugLog)
        return;
    end
    debugLog.trace('ECG print debug trace enabled.');
    try
        pack = ecg_print.debug.writeSamplePack(debugLog);
        addLog(services, sprintf('Debug sample files: %s', char(pack.sampleFolder)));
        addLog(services, sprintf('Debug output folder: %s', char(pack.outputFolder)));
    catch ME
        debugLog.reportException('ecgPrint', 'Debug sample setup failed', ME);
        addLog(services, sprintf('Debug sample setup failed: %s', ME.message));
    end
end

function state = onRecordingChosen(state, payload, services)
    paths = labkit.ui.view.filePaths(payload.event.addedFiles);
    if isempty(paths)
        addLog(services, 'Recording selection cancelled.');
        return;
    end

    state.filepath = paths(1);
    state.fileStatus = string(state.filepath);
    state = clearParsedRecording(state);
    state = updateFilePreview(state, services);
    state = refreshImportParsing(state, false, services);
end

function state = onClearRecording(state, ~, services)
    state = ecg_print.state.initial();
    labkit.ui.view.setValue(services.ui, "roiStart", 0);
    labkit.ui.view.setValue(services.ui, "roiEnd", 0);
    addLog(services, 'Cleared recording.');
end

function state = onRefreshImport(state, ~, services)
    state = refreshImportParsing(state, true, services);
end

function state = refreshImportParsing(state, showAlertOnFailure, services)
    if strlength(state.filepath) == 0
        if showAlertOnFailure
            showError(services, 'No recording selected', ...
                'Open a recording before parsing.');
        else
            state.importStatus = "Open a recording before parsing.";
        end
        return;
    end

    selectedChannel = "";
    ddChannel = services.ui.controls.channel.valueHandle;
    if ~isempty(ddChannel.Items) && ~strcmp(ddChannel.Value, '(none)')
        selectedChannel = string(ddChannel.Value);
    end

    importOpts = ecg_print.io.importOptions( ...
        services.ui.controls.fallbackFs.valueHandle.Value, ...
        services.ui.controls.headerLine.valueHandle.Value, ...
        services.ui.controls.hasHeader.valueHandle.Value, ...
        services.ui.controls.timeColumn.valueHandle.Value, ...
        services.ui.controls.timeUnit.valueHandle.Value, ...
        services.ui.controls.signalColumns.valueHandle.Value);
    [recording, status] = labkit.biosignal.readRecording( ...
        char(state.filepath), importOpts);
    if ~status.ok
        state = clearParsedRecording(state);
        state.importStatus = char("Parse failed. Inspect header/settings, then refresh: " + status.message);
        if showAlertOnFailure
            showError(services, 'Could not parse recording', status.message);
        else
            addLog(services, sprintf('Automatic parse failed: %s', ...
                status.message));
        end
        return;
    end

    state.recording = recording;
    channels = labkit.biosignal.listChannels(recording);
    if isempty(channels)
        state = clearParsedRecording(state);
        state.importStatus = 'Parse failed: no numeric signal channels were found.';
        if showAlertOnFailure
            showError(services, 'Could not parse recording', ...
                'No numeric signal channels were found.');
        end
        return;
    end
    state.channelItems = channels;
    if any(strcmp(channels, selectedChannel))
        state.selectedChannel = selectedChannel;
    else
        state.selectedChannel = string(channels{1});
    end
    state = setCurrentChannel(state, state.selectedChannel, services);
    state.importStatus = ecg_print.view.importStatusText(recording, ...
        numel(channels));
    addLog(services, sprintf('Parsed %d channel(s) from %s', ...
        numel(channels), char(state.filepath)));
end

function state = onPreviewHeader(state, ~, services)
    state = updateFilePreview(state, services);
end

function state = updateFilePreview(state, services)
    if strlength(state.filepath) == 0
        state.filePreview = {'Open a CSV/text file, then use Preview file header.'};
        return;
    end
    state.filePreview = ecg_print.io.previewFileHeader(char(state.filepath), 18);
    addLog(services, sprintf('Previewed file header: %s', ...
        char(state.filepath)));
end

function state = onImportOptionChanged(state, ~, ~)
    if strlength(state.filepath) > 0
        state.importStatus = 'Import settings changed. Click Parse / refresh file.';
    end
end

function state = clearParsedRecording(state)
    state.recording = [];
    state.signal = [];
    state.workingSignal = [];
    state.filteredSignal = [];
    state.events = [];
    state.segments = [];
    state.template = [];
    state.measurements = [];
    state.channelItems = {'(none)'};
    state.selectedChannel = "(none)";
end

function state = onChannelChanged(state, ~, services)
    channelName = services.ui.controls.channel.valueHandle.Value;
    if isempty(state.recording) || strcmp(channelName, '(none)')
        return;
    end
    state = setCurrentChannel(state, channelName, services);
end

function state = setCurrentChannel(state, channelName, services)
    state.selectedChannel = string(channelName);
    state.signal = labkit.biosignal.getChannel(state.recording, channelName);
    state.workingSignal = state.signal;
    state.filteredSignal = [];
    state.events = [];
    state.segments = [];
    state.template = [];
    state.measurements = [];
    if ~isempty(state.signal.time)
        labkit.ui.view.setValue(services.ui, "roiStart", 0);
        labkit.ui.view.setValue(services.ui, "roiEnd", max(state.signal.time));
    end
end

function state = onAnalyze(state, ~, services)
    if isempty(state.signal)
        showError(services, 'No channel selected', ...
            'Open a recording and select a channel first.');
        return;
    end

    ui = services.ui;
    try
        timeRange = [ui.controls.roiStart.valueHandle.Value ...
            ui.controls.roiEnd.valueHandle.Value];
        highCut = min(ui.controls.highCut.valueHandle.Value, ...
            max(ui.controls.lowCut.valueHandle.Value + eps, ...
            0.45 * state.signal.fs));
        filterSpec = struct('type', 'bandpass', 'cutoffHz', ...
            [ui.controls.lowCut.valueHandle.Value highCut]);
        fullFiltered = labkit.biosignal.filterSignal(state.signal, filterSpec);
        if timeRange(2) > timeRange(1)
            state.workingSignal = labkit.biosignal.cropSignal( ...
                state.signal, timeRange);
            state.filteredSignal = labkit.biosignal.cropSignal( ...
                fullFiltered, timeRange);
        else
            state.workingSignal = state.signal;
            state.filteredSignal = fullFiltered;
        end
        peakOpts = struct('polarity', 'auto', ...
            'method', ecg_print.ops.peakMethodValue( ...
            ui.controls.peakMethod.valueHandle.Value), ...
            'minDistanceSec', ui.controls.peakDistance.valueHandle.Value, ...
            'thresholdStd', 2.8);
        state.events = labkit.biosignal.detectEcgPeaks( ...
            state.filteredSignal, peakOpts);
        halfWin = ui.controls.segmentWindow.valueHandle.Value;
        state.segments = labkit.biosignal.segmentByEvents( ...
            state.filteredSignal, state.events, [-halfWin halfWin]);
        state.template = labkit.biosignal.buildTemplate( ...
            state.segments, struct('topN', ...
            ui.controls.templateTopN.valueHandle.Value));
        state.measurements = labkit.biosignal.measureSegments( ...
            state.segments, state.template);

        addLog(services, sprintf(['Filtered channel, then analyzed ROI ' ...
            'with %s: %d peaks, %d valid segments.'], ...
            ui.controls.peakMethod.valueHandle.Value, ...
            numel(state.events.index), size(state.segments.values, 2)));
    catch ME
        showException(services, 'Analysis failed', ME);
    end
end

function state = onExportSegments(state, ~, services)
    if isempty(state.measurements) || isempty(state.measurements.perSegment)
        showError(services, 'No segment SNR', ...
            'Analyze a signal before exporting segment SNR.');
        return;
    end
    [out, cancelled] = labkit.ui.app.promptOutputFile( ...
        'ecg_segment_snr.csv', 'Export segment SNR CSV', ...
        'ecg_segment_snr.csv');
    if cancelled
        addLog(services, 'Segment SNR export cancelled.');
        return;
    end
    writetable(ecg_print.export.analysisTable(state.measurements.perSegment, ...
        services.ui.controls.smoothBeats.valueHandle.Value), out);
    addLog(services, sprintf('Exported segment SNR CSV: %s', char(out)));
end

function state = onExportWaveform(state, ~, services)
    [out, cancelled] = labkit.ui.app.promptOutputFile( ...
        'ecg_waveform.png', 'Export waveform PNG', 'ecg_waveform.png');
    if cancelled
        addLog(services, 'Waveform export cancelled.');
        return;
    end
    exportgraphics(services.ui.controls.previewAxes.axesById.wave, out, ...
        'Resolution', 300);
    addLog(services, sprintf('Exported waveform PNG: %s', char(out)));
end

function state = onRefreshOnly(state, ~, ~)
end

function showError(services, titleText, message)
    labkit.ui.app.showAlert(services.figure, char(message), titleText);
    addLog(services, sprintf('%s: %s', titleText, message));
end

function showException(services, titleText, exception)
    if isDebugEnabled(services.debug)
        services.debug.reportException('ecgPrint', titleText, exception);
    end
    showError(services, titleText, exception.message);
end

function addLog(services, message)
    labkit.ui.view.appendLog(services.ui, 'appLog', message);
    if isDebugEnabled(services.debug)
        services.debug.append(message);
    end
end

function tf = isDebugEnabled(debugLog)
    tf = isstruct(debugLog) && isfield(debugLog, 'enabled') && ...
        logical(debugLog.enabled);
end
