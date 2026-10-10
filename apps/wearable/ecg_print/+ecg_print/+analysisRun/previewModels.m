function model = previewModels(cache)
%PREVIEWMODELS Retain original waveform samples and raw R coordinates for the full applied interval.
model = struct('time',[],'ecg',[],'peakTime',[], ...
    'peakValues',[],'beats',table(),'unit',"ADC counts");
if isempty(cache.signal), return; end
signal = cache.workingSignal;
model.unit = ecg_print.analysisRun.signalUnit(signal);
model.time = signal.time; model.ecg = signal.values;
if isempty(cache.ecgNext), return; end
r = cache.ecgNext; model.beats = r.perBeat;
model.peakTime = (r.rPeaks-1)/r.fs;
model.peakValues = r.raw(r.rPeaks);
end
