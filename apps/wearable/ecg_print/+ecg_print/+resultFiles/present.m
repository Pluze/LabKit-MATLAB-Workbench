function view = present(hasMeasurements, hasWaveform)
view = labkit.app.view.Snapshot().enabled("exportSegments", hasMeasurements).enabled("exportWaveform", hasWaveform);
end
