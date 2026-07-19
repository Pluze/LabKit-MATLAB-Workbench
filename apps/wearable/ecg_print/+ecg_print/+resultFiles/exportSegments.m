function state = exportSegments(state, context)
if isempty(state.session.cache.measurements) || isempty(state.session.cache.measurements.perSegment), context.alert("Analyze a signal before exporting segment SNR.", "No segment SNR"); return; end
chosen = context.chooseOutputFile(["*.csv", "CSV files (*.csv)"], "ecg_segment_snr.csv"); if chosen.Cancelled, return; end
path = string(chosen.Value); writetable(ecg_print.resultFiles.analysisTable(state.session.cache.measurements.perSegment, state.project.parameters.smoothBeats), path);
state.project.results.lastSegmentExport = struct("csvPath", path);
end
