% App-owned implementation for ecg_print.resultFiles.present within the ecg_print product workflow.
function view = present(hasMeasurements, hasWaveform)
view = labkit.app.view.Snapshot().enabled("exportSegments", hasMeasurements).enabled("exportWaveform", hasWaveform);
end
