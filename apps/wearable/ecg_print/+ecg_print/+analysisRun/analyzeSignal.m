function cache = analyzeSignal(cache, parameters)
%ANALYZESIGNAL Rebuild ECG analysis products from one decoded signal cache.
%
% Usage:
%   cache = ecg_print.analysisRun.analyzeSignal(cache, parameters)
%
% Description:
%   Runs the numerical pipeline used by ECG Print without opening the app. It
%   filters the complete decoded channel, optionally crops the raw and filtered
%   signals to a time interval, detects ECG peaks, extracts event-centered
%   segments, builds a representative template, and measures each segment
%   against that template. Filtering before cropping reduces FFT boundary
%   artifacts at the requested interval edges.
%
%   The input structure is returned with six rebuildable analysis fields
%   replaced. Other cache fields are preserved, so callers can keep source and
%   import metadata beside the derived results. The function creates no
%   graphics and reads or writes no files.
%
% Inputs:
%   cache - Scalar structure containing cache.signal. The signal must have
%       corresponding time and values vectors, a positive sample rate fs in
%       hertz, a displayName, and a metadata structure. These are the fields
%       used by the biosignal functions in this pipeline.
%   parameters - Scalar structure containing every field listed under
%       Parameter Fields. Unlike the ECG Print controls, this direct API does
%       not fill missing fields or sanitize invalid values.
%
% Parameter Fields:
%   lowCut - Lower band-pass cutoff in hertz. Supply a finite nonnegative
%       scalar below highCut and below 45% of the sample rate.
%   highCut - Requested upper band-pass cutoff in hertz. For a conventional
%       lowCut, the effective value is min(highCut, 0.45*fs). If lowCut is at
%       or above that limit, the cap becomes lowCut+eps so the two cutoffs can
%       remain ordered. Callers should avoid that case because it leaves no
%       useful safety margin below Nyquist.
%   roiStart - Start time in seconds on cache.signal.time.
%   roiEnd - End time in seconds on cache.signal.time. When roiEnd is greater
%       than roiStart, samples at both endpoints are retained and the cropped
%       time vectors restart at zero. Otherwise the full signal is analyzed.
%   peakMethod - ECG Print method label: "QRS streaming", "Pan-Tompkins", or
%       "Local peaks". Any other value currently falls back to QRS streaming.
%   peakDistance - Minimum accepted peak spacing in seconds. Use a positive
%       finite scalar.
%   segmentWindow - Positive half-width in seconds for the symmetric interval
%       [-segmentWindow, segmentWindow] around every peak. Peaks too close to
%       either signal boundary are omitted. Values below 0.5 seconds may not
%       cover all default noise-measurement windows and can yield NaN metrics.
%   templateTopN - Number of highest-correlation segments requested for the
%       template. buildTemplate rounds the value and limits it to the available
%       segment count, with a minimum of one for nonempty input.
%
% Fixed Analysis Settings:
%   The detector uses automatic polarity and a 2.8 robust-standard-deviation
%   threshold setting. Segment measurements use signal window [-0.06 0.06]
%   seconds and noise windows [-0.30 -0.20] and [0.40 0.50] seconds. Call the
%   individual labkit.biosignal functions when those settings must be changed.
%
% Outputs:
%   cache - Updated analysis cache with the fields below.
%
% Cache Fields:
%   signal - Original decoded signal, unchanged.
%   workingSignal - Raw full signal or selected time crop.
%   filteredSignal - Corresponding band-pass filtered signal.
%   events - Peak anchors from labkit.biosignal.detectEcgPeaks.
%   segments - Retained event-centered columns from segmentByEvents.
%   template - Representative waveform and segment ranking from buildTemplate.
%   measurements - Per-segment and summary signal-quality tables from
%       measureSegments. Empty detections lead to empty downstream results
%       instead of invented measurements.
%
% Errors:
%   Missing cache or parameter fields raise normal MATLAB field-reference
%   errors. Invalid signal shapes, time ranges, filter settings, or detector
%   choices raise the documented errors from the corresponding
%   labkit.biosignal function; this function does not catch them.
%
% Example:
%   fs = 100;
%   time = (0:1/fs:6)';
%   values = 0.02*sin(2*pi*1.5*time);
%   values(101:100:501) = values(101:100:501) + 1;
%   signal = struct('time', time, 'values', values, 'fs', fs, ...
%       'displayName', "Synthetic ECG", 'metadata', struct());
%   cache = struct('signal', signal);
%   parameters = struct('lowCut', 0.5, 'highCut', 40, ...
%       'roiStart', 0, 'roiEnd', 0, 'peakMethod', "Local peaks", ...
%       'peakDistance', 0.5, 'segmentWindow', 0.7, 'templateTopN', 5);
%   cache = ecg_print.analysisRun.analyzeSignal(cache, parameters);
%   assert(isfield(cache, 'measurements'))
%
% See also labkit.biosignal.filterSignal,
%   labkit.biosignal.cropSignal,
%   labkit.biosignal.detectEcgPeaks,
%   labkit.biosignal.segmentByEvents,
%   labkit.biosignal.buildTemplate,
%   labkit.biosignal.measureSegments

    signal = cache.signal;
    nyquistSafetyFraction = 0.45;
    % Constant: keep the upper cutoff at 90% of Nyquist when lowCut permits.
    highCut = min(parameters.highCut, ...
        max(parameters.lowCut + eps, nyquistSafetyFraction * signal.fs));
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
    appThresholdStd = 2.8;
    % Constant: ECG Print's empirical default for robust local peak screening.
    peakOptions = struct("polarity", "auto", ...
        "method", ecg_print.analysisRun.peakMethodValue(parameters.peakMethod), ...
        "minDistanceSec", parameters.peakDistance, ...
        "thresholdStd", appThresholdStd);
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
