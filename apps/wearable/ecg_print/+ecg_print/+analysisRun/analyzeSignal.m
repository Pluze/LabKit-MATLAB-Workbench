function cache = analyzeSignal(cache, parameters)
%ANALYZESIGNAL Rebuild ECG analysis products from one decoded signal cache.
%
% Usage:
%   cache = ecg_print.analysisRun.analyzeSignal(cache, parameters)
%
% Description:
%   Runs the numerical pipeline used by ECG Print without opening the app. It
%   filters the complete decoded channel with a stable App-owned FIR,
%   optionally crops the raw and filtered
%   signals to a time interval, detects ECG peaks, extracts event-centered
%   segments, builds a representative template, and measures each segment
%   against that template. Filtering before cropping keeps convolution
%   boundary handling outside the requested interval edges. The symmetric
%   FIR uses reflection padding and compensates its linear-phase delay.
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
%       scalar below highCut and no greater than the Nyquist frequency.
%   highCut - Requested upper band-pass cutoff in hertz, capped at the
%       Nyquist frequency. The complete [0 fs/2] interval is a true bypass.
%   useAnalysisBandForPeaks - Optional logical scalar. True or absent uses
%       the main filtered signal for detection. False applies a second
%       band-pass to the main filtered signal for peak detection only.
%   peakLowCut, peakHighCut - Secondary detector-band cutoffs in hertz when
%       useAnalysisBandForPeaks is false. Detected indices anchor segments
%       cut from the main filtered signal, so this band cannot change the
%       samples used for templates or quality measurements.
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
%   peakDetectionSignal - Signal used only to locate peak indices. This is
%       filteredSignal unless the optional detector band is enabled.
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
% See also ecg_print.analysisRun.firDesign,
%   ecg_print.analysisRun.applyFir,
%   labkit.biosignal.cropSignal,
%   labkit.biosignal.detectEcgPeaks,
%   labkit.biosignal.segmentByEvents,
%   labkit.biosignal.buildTemplate,
%   labkit.biosignal.measureSegments

    signal = cache.signal;
    nyquist = 0.5 * signal.fs;
    highCut = min(parameters.highCut, ...
        max(parameters.lowCut + eps, nyquist));
    analysisBand = [parameters.lowCut highCut];
    analysisFilter = ecg_print.analysisRun.firDesign( ...
        signal.fs, analysisBand);
    fullFiltered = ecg_print.analysisRun.applyFir( ...
        signal, analysisFilter);
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
    useAnalysisBand = ~isfield(parameters, "useAnalysisBandForPeaks") || ...
        parameters.useAnalysisBandForPeaks;
    cache.peakDetectionSignal = cache.filteredSignal;
    if ~useAnalysisBand
        peakLowCut = parameterValue(parameters, "peakLowCut", parameters.lowCut);
        peakHighCut = parameterValue(parameters, "peakHighCut", highCut);
        peakFilter = ecg_print.analysisRun.firDesign( ...
            signal.fs, [peakLowCut peakHighCut]);
        cache.peakDetectionSignal = ecg_print.analysisRun.applyFir( ...
            cache.filteredSignal, peakFilter);
    end
    cache.events = labkit.biosignal.detectEcgPeaks( ...
        cache.peakDetectionSignal, peakOptions);
    cache.segments = labkit.biosignal.segmentByEvents( ...
        cache.filteredSignal, cache.events, ...
        [-parameters.segmentWindow parameters.segmentWindow]);
    cache.template = labkit.biosignal.buildTemplate( ...
        cache.segments, struct("topN", parameters.templateTopN));
    cache.measurements = labkit.biosignal.measureSegments( ...
        cache.segments, cache.template);
    cache.filterDetails = ecg_print.analysisRun.filterDetailsModel( ...
        cache, parameters);
end

function value = parameterValue(parameters, name, fallback)
if isfield(parameters, name)
    value = parameters.(name);
else
    value = fallback;
end
end
