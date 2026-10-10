function cache = analyzeSignal(cache, parameters, progress)
%ANALYZESIGNAL Run the single ECGNExT file-analysis pipeline without graphics.
%   cache = ecg_print.analysisRun.analyzeSignal(cache, parameters) accepts
%   cache.signal (LabKit signal) and parameters.roiStart, roiEnd, peakMethod,
%   peakDistance. End<=start selects the full record. peakMethod is "QRS
%   streaming", "Pan-Tompkins", or "Local peaks"; peakDistance is seconds.
%   Optional progress(completed,total) reports extraction-window progress.
%   Source is preserved in cache.signal. workingSignal is the prepared raw
%   1000 Hz ROI; filteredSignal is fixed 0.5-40 Hz Butterworth ECG;
%   peakDetectionSignal is a fixed 5-20 Hz FIR on prepared raw ECG for
%   peak localization, independent of morphology-filter edge transients.
%   cache.events contains 1000 Hz R indices, cache.ecgNext contains exact
%   extracted noise, per-beat measurements, and preparation provenance.
%   Short input returns explicit unavailable status. Import, preparation,
%   detector, and unexpected extraction errors propagate. No files or GUI.
%   See also ecg_print.analysisRun.prepareSignal,
%       ecg_print.analysisRun.ecgNextAnalysis.
if nargin < 3, progress = []; end
parameters = ecg_print.analysisRun.sanitizeParameters(parameters, cache.signal.fs);
[cache.workingSignal, cache.filteredSignal, preparation, cache.peakDetectionSignal] = ...
    ecg_print.analysisRun.prepareSignal(cache.signal, ...
    [parameters.roiStart parameters.roiEnd]);
options = struct('polarity',"auto", 'method', ...
    ecg_print.analysisRun.peakMethodValue(parameters.peakMethod), ...
    'minDistanceSec',parameters.peakDistance,'thresholdStd',2.8);
cache.events = labkit.biosignal.detectEcgPeaks(cache.peakDetectionSignal,options);
cache.events = ecg_print.analysisRun.refineRPeaks(cache.events, ...
    cache.workingSignal,cache.peakDetectionSignal,parameters.peakDistance);
cache.ecgNext = ecg_print.analysisRun.ecgNextAnalysis( ...
    cache.workingSignal,cache.filteredSignal,cache.events,progress);
cache.ecgNext.preparation = preparation;
cache.ecgNext.parameters = parameters;
cache.ecgNext.peakLocalization = cache.events.metadata.rawLocalization;
cache.ecgNext.unit = ecg_print.analysisRun.signalUnit(cache.signal);
cache.ecgNext.statistics = ecg_print.analysisRun.beatStatistics(cache.ecgNext.perBeat,cache.ecgNext.unit);
end
