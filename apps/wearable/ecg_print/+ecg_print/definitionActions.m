% App-owned Runtime V2 actions for ECG Print. Handlers own source parsing,
% channel/analysis transitions, and result exports without control reads,
% figure callback state, UI-axis access, or startup plumbing.
function actions = definitionActions()
    actions = struct( ...
        "recordingChosen", @onRecordingChosen, ...
        "previewHeader", @onPreviewHeader, ...
        "importOptionChanged", @onImportOptionChanged, ...
        "refreshImport", @onRefreshImport, ...
        "channelChanged", @onChannelChanged, ...
        "analyze", @onAnalyze, ...
        "exportSegments", @onExportSegments, ...
        "exportWaveform", @onExportWaveform);
end

function state = onRecordingChosen(state, event, services)
    filepath = firstEventPath(event, services);
    if strlength(filepath) == 0
        state = services.workflow.log(state, "Recording selection cancelled.");
        return;
    end
    state.project.inputs.sources = services.project.sourceRecord( ...
        "recording", "biosignalRecording", filepath, true);
    state.session.cache.filepath = filepath;
    state.session.cache.filePreview = ...
        ecg_print.sourceFiles.previewFileHeader(char(filepath), 18);
    state = parseRecording(state, false, services);
end

function state = onPreviewHeader(state, ~, services)
    filepath = state.session.cache.filepath;
    if strlength(filepath) == 0
        state.session.cache.filePreview = ...
            {'Open a CSV/text file, then use Preview file header.'};
        return;
    end
    state.session.cache.filePreview = ...
        ecg_print.sourceFiles.previewFileHeader(char(filepath), 18);
    state = services.workflow.log(state, ...
        "Previewed file header: " + filepath);
end

function state = onImportOptionChanged(state, ~, ~)
    state = clearAnalysis(state);
    if ~isempty(state.project.inputs.sources)
        state.session.workflow.importStatus = ...
            "Import settings changed. Click Parse / refresh file.";
    end
end

function state = onRefreshImport(state, ~, services)
    state = parseRecording(state, true, services);
end

function state = parseRecording(state, showAlert, services)
    filepath = state.session.cache.filepath;
    if strlength(filepath) == 0
        if showAlert
            services.dialogs.alert( ...
                "Open a recording before parsing.", "No recording selected");
        else
            state.session.workflow.importStatus = ...
                "Open a recording before parsing.";
        end
        return;
    end
    try
        [cache, importStatus] = ecg_print.sourceFiles.loadRecording( ...
            filepath, state.project.parameters, ...
            state.project.parameters.channel);
        cache.filePreview = state.session.cache.filePreview;
        state.session.cache = cache;
        state.session.workflow.importStatus = importStatus;
        state.project.parameters.channel = string(cache.signal.displayName);
        state.project.parameters.roiStart = 0;
        state.project.parameters.roiEnd = max(cache.signal.time);
        state.project.results.lastAnalysis = struct();
        state.project.results.lastSegmentExport = [];
        state.project.results.lastWaveformExport = [];
        state = services.workflow.log(state, sprintf( ...
            "Parsed %d channel(s) from %s", ...
            numel(cache.channelItems), filepath));
    catch ME
        services.diagnostics.report("Recording parse failed", ME);
        state = clearDecodedRecording(state);
        state.session.workflow.importStatus = ...
            "Parse failed. Inspect header/settings, then refresh: " + ME.message;
        state = services.workflow.log(state, ...
            "Recording parse failed: " + ME.message);
        if showAlert
            services.dialogs.alert(ME.message, "Could not parse recording");
        end
    end
end

function state = onChannelChanged(state, event, services)
    channel = string(event.value);
    if isempty(state.session.cache.recording) || channel == "(none)"
        return;
    end
    try
        signal = labkit.biosignal.getChannel( ...
            state.session.cache.recording, channel);
    catch ME
        services.diagnostics.report("Channel selection failed", ME);
        services.dialogs.alert(ME.message, "Channel selection failed");
        return;
    end
    state.project.parameters.channel = channel;
    state.project.parameters.roiStart = 0;
    state.project.parameters.roiEnd = max(signal.time);
    state.session.cache.signal = signal;
    state.session.cache.workingSignal = signal;
    state = clearAnalysis(state);
    state = services.workflow.log(state, "Selected channel: " + channel);
end

function state = onAnalyze(state, ~, services)
    if isempty(state.session.cache.signal)
        services.dialogs.alert( ...
            "Open a recording and select a channel first.", ...
            "No channel selected");
        return;
    end
    state.project.parameters = sanitizeAnalysisParameters( ...
        state.project.parameters, state.session.cache.signal.fs);
    try
        state.session.cache = ecg_print.analysisRun.analyzeSignal( ...
            state.session.cache, state.project.parameters);
    catch ME
        services.diagnostics.report("Analysis failed", ME);
        services.dialogs.alert(ME.message, "Analysis failed");
        state = services.workflow.log(state, "Analysis failed: " + ME.message);
        return;
    end
    state.project.results.lastAnalysis = analysisRecord(state);
    state.project.results.lastSegmentExport = [];
    state.project.results.lastWaveformExport = [];
    state = services.workflow.log(state, sprintf( ...
        "Analyzed ROI with %s: %d peaks, %d valid segments.", ...
        state.project.parameters.peakMethod, ...
        numel(state.session.cache.events.index), ...
        size(state.session.cache.segments.values, 2)));
end

function state = onExportSegments(state, ~, services)
    measurements = state.session.cache.measurements;
    if isempty(measurements) || isempty(measurements.perSegment)
        services.dialogs.alert( ...
            "Analyze a signal before exporting segment SNR.", ...
            "No segment SNR");
        return;
    end
    filename = "ecg_segment_snr.csv";
    [out, cancelled] = services.dialogs.outputFile( ...
        '*.csv', 'Export segment SNR CSV', filename);
    if cancelled
        state = services.workflow.log(state, "Segment SNR export cancelled.");
        return;
    end
    analysis = ecg_print.resultFiles.analysisTable( ...
        measurements.perSegment, state.project.parameters.smoothBeats);
    writetable(analysis, out);
    [manifestPath, ~] = writeManifest(state, services, out, ...
        "ecgSegmentSnr", "text/csv", "ecg_segment_snr.labkit.json");
    state.project.results.lastSegmentExport = struct( ...
        "csvPath", string(out), "manifestPath", string(manifestPath));
    state = services.workflow.log(state, ...
        "Exported segment SNR CSV: " + string(out));
end

function state = onExportWaveform(state, ~, services)
    request = ecg_print.userInterface.waveformPlotRequest( ...
        state.session.cache.workingSignal, ...
        state.session.cache.filteredSignal, state.session.cache.events);
    if ~request.ok
        services.dialogs.alert( ...
            "Open a recording before exporting a waveform.", ...
            "No waveform");
        return;
    end
    filename = "ecg_waveform.png";
    [out, cancelled] = services.dialogs.outputFile( ...
        '*.png', 'Export waveform PNG', filename);
    if cancelled
        state = services.workflow.log(state, "Waveform export cancelled.");
        return;
    end
    ecg_print.resultFiles.writeWaveformPng(request, out);
    [manifestPath, ~] = writeManifest(state, services, out, ...
        "ecgWaveform", "image/png", "ecg_waveform.labkit.json");
    state.project.results.lastWaveformExport = struct( ...
        "pngPath", string(out), "manifestPath", string(manifestPath));
    state = services.workflow.log(state, ...
        "Exported waveform PNG: " + string(out));
end

function record = analysisRecord(state)
    cache = state.session.cache;
    perSegment = table();
    summary = struct();
    if ~isempty(cache.measurements)
        perSegment = cache.measurements.perSegment;
        summary = cache.measurements.summary;
    end
    record = struct( ...
        "channel", state.project.parameters.channel, ...
        "eventCount", numel(cache.events.index), ...
        "segmentCount", size(cache.segments.values, 2), ...
        "summary", summary, "perSegment", perSegment);
end

function [manifestPath, report] = writeManifest( ...
        state, services, outputPath, id, mediaType, manifestName)
    [folder, name, extension] = fileparts(outputPath);
    output = services.results.output(id, "primary", ...
        string(name) + string(extension), mediaType);
    summary = struct();
    if ~isempty(fieldnames(state.project.results.lastAnalysis))
        summary = rmfield(state.project.results.lastAnalysis, "perSegment");
    end
    spec = struct( ...
        "Outputs", output, "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, "Summary", summary, ...
        "ManifestName", manifestName);
    [manifestPath, report] = services.results.writeManifest(folder, spec);
end

function state = clearAnalysis(state)
    state.session.cache.filteredSignal = [];
    state.session.cache.events = [];
    state.session.cache.segments = [];
    state.session.cache.template = [];
    state.session.cache.measurements = [];
    if ~isempty(state.session.cache.signal)
        state.session.cache.workingSignal = state.session.cache.signal;
    end
    state.project.results.lastAnalysis = struct();
    state.project.results.lastSegmentExport = [];
    state.project.results.lastWaveformExport = [];
end

function state = clearDecodedRecording(state)
    filepath = state.session.cache.filepath;
    preview = state.session.cache.filePreview;
    project = ecg_print.appLifecycle.createProject();
    empty = ecg_print.appLifecycle.createSession(project);
    state.session.cache = empty.cache;
    state.session.cache.filepath = filepath;
    state.session.cache.filePreview = preview;
    state.project.parameters.channel = "(none)";
    state = clearAnalysis(state);
end

function parameters = sanitizeAnalysisParameters(parameters, sampleRate)
    parameters.roiStart = finiteNonnegative(parameters.roiStart, 0);
    parameters.roiEnd = finiteNonnegative(parameters.roiEnd, 0);
    parameters.lowCut = finiteNonnegative(parameters.lowCut, 0.5);
    parameters.highCut = finiteNonnegative(parameters.highCut, 40);
    parameters.highCut = min(parameters.highCut, ...
        max(parameters.lowCut + eps, 0.45 * sampleRate));
    parameters.peakDistance = max(eps, ...
        finiteNonnegative(parameters.peakDistance, 0.28));
    parameters.segmentWindow = max(eps, ...
        finiteNonnegative(parameters.segmentWindow, 0.7));
    parameters.templateTopN = max(1, round( ...
        finiteNonnegative(parameters.templateTopN, 30)));
    parameters.smoothBeats = max(1, round( ...
        finiteNonnegative(parameters.smoothBeats, 15)));
end

function value = finiteNonnegative(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
    value = max(0, value);
end

function filepath = firstEventPath(event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    filepath = "";
    if ~isempty(paths)
        filepath = paths(1);
    end
end
