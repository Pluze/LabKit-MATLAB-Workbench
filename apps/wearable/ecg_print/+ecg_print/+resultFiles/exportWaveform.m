function state = exportWaveform(state, context)
request = ecg_print.analysisRun.waveformPlotRequest(state.session.cache.workingSignal, state.session.cache.filteredSignal, state.session.cache.events);
if ~request.ok, context.alert("Open a recording before exporting a waveform.", "No waveform"); return; end
chosen = context.chooseOutputFile(["*.png", "PNG files (*.png)"], "ecg_waveform.png"); if chosen.Cancelled, return; end
path = string(chosen.Value); ecg_print.resultFiles.writeWaveformPng(request, path); state.project.results.lastWaveformExport = struct("pngPath", path);
end
