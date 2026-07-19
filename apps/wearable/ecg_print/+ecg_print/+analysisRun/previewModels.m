function models = previewModels(cache, parameters)
emptyRequest = struct();
models = repmat(struct( ...
    "kind", "", "request", emptyRequest, ...
    "analysis", table(), "smoothBeats", parameters.smoothBeats), 1, 4);
models(1).kind = "wave";
models(1).request = ecg_print.analysisRun.waveformPlotRequest( ...
    cache.workingSignal, cache.filteredSignal, cache.events);
analysis = table();
if ~isempty(cache.measurements) && ~isempty(cache.measurements.perSegment)
    analysis = ecg_print.resultFiles.analysisTable(cache.measurements.perSegment, parameters.smoothBeats);
end
models(2).kind = "noise";
models(2).analysis = analysis;
models(3).kind = "snr";
models(3).analysis = analysis;
models(4).kind = "template";
models(4).request = ecg_print.analysisRun.templatePlotRequest( ...
    cache.segments, cache.template, cache.measurements, ...
    parameters.templateView);
end
