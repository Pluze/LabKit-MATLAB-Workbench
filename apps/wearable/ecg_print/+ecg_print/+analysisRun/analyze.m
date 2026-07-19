function state = analyze(state, context)
if isempty(state.session.cache.signal), context.alert("Open a recording and select a channel first.", "No channel selected"); return; end
try
    state.session.cache = ecg_print.analysisRun.analyzeSignal(state.session.cache, state.project.parameters);
catch ME
    context.reportError("ECG analysis", ME); context.alert(ME.message, "Analysis failed"); return;
end
cache = state.session.cache;
state.project.results.lastAnalysis = struct("channel", state.project.parameters.channel, "eventCount", numel(cache.events.index), "segmentCount", size(cache.segments.values, 2), "summary", cache.measurements.summary, "perSegment", cache.measurements.perSegment);
state.project.results.lastSegmentExport = []; state.project.results.lastWaveformExport = [];
end
