% Expected callers: ECG Runtime V2 actions and session reconstruction. Inputs
% are a decoded ECG cache plus durable analysis parameters. Output replaces
% only rebuildable filtered/event/segment/template/measurement cache fields.
function cache = analyzeSignal(cache, parameters)
%ANALYZESIGNAL Rebuild ECG analysis products from one decoded signal cache.
%   cache = ecg_print.analysisRun.analyzeSignal(cache, parameters) expects
%   cache.signal to be a normalized biosignal channel record with time,
%   values, and fs. parameters supplies lowCut, highCut, roiStart, roiEnd,
%   peakMethod, peakDistance, segmentWindow, and templateTopN.
%
%   The returned cache updates workingSignal, filteredSignal, events, segments,
%   template, and measurements. A valid positive ROI selects a time crop;
%   otherwise the full signal is analyzed. The high cutoff is bounded below
%   0.45*fs. Peak labels map through peakMethodValue. This function performs no
%   UI or file writes and uses the same biosignal facade sequence as the app.
%
%   See also labkit.biosignal.filterSignal,
%   labkit.biosignal.detectEcgPeaks, labkit.biosignal.measureSegments.
    signal = cache.signal;
    highCut = min(parameters.highCut, ...
        max(parameters.lowCut + eps, 0.45 * signal.fs));
    filterSpec = struct("type", "bandpass", ...
        "cutoffHz", [parameters.lowCut highCut]);
    fullFiltered = labkit.biosignal.filterSignal(signal, filterSpec);
    timeRange = [parameters.roiStart parameters.roiEnd];
    if timeRange(2) > timeRange(1)
        cache.workingSignal = labkit.biosignal.cropSignal(signal, timeRange);
        cache.filteredSignal = labkit.biosignal.cropSignal( ...
            fullFiltered, timeRange);
    else
        cache.workingSignal = signal;
        cache.filteredSignal = fullFiltered;
    end
    peakOptions = struct("polarity", "auto", ...
        "method", ecg_print.analysisRun.peakMethodValue(parameters.peakMethod), ...
        "minDistanceSec", parameters.peakDistance, "thresholdStd", 2.8);
    cache.events = labkit.biosignal.detectEcgPeaks( ...
        cache.filteredSignal, peakOptions);
    cache.segments = labkit.biosignal.segmentByEvents( ...
        cache.filteredSignal, cache.events, ...
        [-parameters.segmentWindow parameters.segmentWindow]);
    cache.template = labkit.biosignal.buildTemplate( ...
        cache.segments, struct("topN", parameters.templateTopN));
    cache.measurements = labkit.biosignal.measureSegments( ...
        cache.segments, cache.template);
end
