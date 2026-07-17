% Expected caller: Runtime V2. Input is canonical ECG state. Output is one
% deterministic control/table/log/four-axis presentation without UI registry
% reads, graphics handles, IO, or analysis side effects.
function view = presentWorkbench(state)
    cache = state.session.cache;
    parameters = state.project.parameters;
    hasSource = ~isempty(state.project.inputs.sources);
    hasSignal = ~isempty(cache.signal);
    hasMeasurements = ~isempty(cache.measurements) && ...
        ~isempty(cache.measurements.perSegment);
    view = struct();
    view.controls.recording = sourcePanel(state.project.inputs.sources);
    view.controls.importStatus = valueSpec(state.session.workflow.importStatus);
    view.controls.filePreview = valueSpec(cache.filePreview);
    view.controls.channel = channelSpec(cache);
    view.controls.summaryTable = tableSpec( ...
        ecg_print.userInterface.summaryRows(cache.signal, cache.events, ...
        cache.segments, cache.measurements));
    view.controls.previewHeader = enabledSpec(hasSource);
    view.controls.refreshImport = enabledSpec(hasSource);
    view.controls.analyze = enabledSpec(hasSignal);
    view.controls.exportSegments = enabledSpec(hasMeasurements);
    view.controls.exportWaveform = enabledSpec(~isempty(cache.workingSignal));
    models = previewModels(cache, parameters);
    view.previews.previewAxes.Axes.wave = axisSpec(models.wave);
    view.previews.previewAxes.Axes.noise = axisSpec(models.noise);
    view.previews.previewAxes.Axes.snr = axisSpec(models.snr);
    view.previews.previewAxes.Axes.template = axisSpec(models.template);
end

function models = previewModels(cache, parameters)
    models.wave = struct("kind", "wave", "request", ...
        ecg_print.userInterface.waveformPlotRequest( ...
        cache.workingSignal, cache.filteredSignal, cache.events));
    analysis = table();
    if ~isempty(cache.measurements) && ~isempty(cache.measurements.perSegment)
        analysis = ecg_print.resultFiles.analysisTable( ...
            cache.measurements.perSegment, parameters.smoothBeats);
    end
    models.noise = struct("kind", "noise", "analysis", analysis, ...
        "smoothBeats", parameters.smoothBeats);
    models.snr = struct("kind", "snr", "analysis", analysis, ...
        "smoothBeats", parameters.smoothBeats);
    models.template = struct("kind", "template", "request", ...
        ecg_print.userInterface.templatePlotRequest(cache.segments, ...
        cache.template, cache.measurements, parameters.templateView));
end

function spec = sourcePanel(sources)
    files = struct("id", {}, "path", {}, "status", {});
    status = "No file loaded";
    filepath = labkit.ui.runtime.sourcePaths(sources, "recording");
    if strlength(filepath) > 0
        files = struct("id", "item1", "path", filepath, "status", "");
        status = filepath;
    end
    spec = struct("Files", files, "Status", status);
end

function spec = channelSpec(cache)
    items = cache.channelItems;
    value = "(none)";
    if ~isempty(cache.signal)
        value = string(cache.signal.displayName);
    end
    spec = struct();
    spec.Items = items;
    spec.Value = value;
    spec.Enabled = ~isempty(cache.signal);
end

function spec = axisSpec(model)
    spec = struct("Renderer", "previewAxis", "Model", model);
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = tableSpec(value)
    spec = struct();
    spec.Data = value;
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end
