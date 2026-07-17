function events = detectEcgPeaks(signal, opts)
%DETECTECGPEAKS Detect ECG/QRS peaks as event anchors.
%
% Usage:
%   events = labkit.biosignal.detectEcgPeaks(signal)
%   events = labkit.biosignal.detectEcgPeaks(signal, opts)
%
% Description:
%   Detects beat anchors from one ECG-like signal. The function first obtains
%   the documented defaults for opts.method, then replaces them with fields
%   supplied in opts. Input time, sample indices, and raw amplitudes are
%   preserved in the returned events so the anchors can be used directly by
%   labkit.biosignal.segmentByEvents.
%
%   qrs-streaming uses a causal moving baseline and slope envelope, adaptive
%   signal and noise levels, a rolling morphology template, and optional
%   median-polarity review. pan-tompkins uses a QRS-band signal, squared
%   derivative energy, moving integration, adaptive thresholding, and search
%   back. local applies a robust amplitude threshold followed by nonmaximum
%   suppression. Pan-Tompkins and streaming candidates are finally moved to
%   nearby peaks in the raw signal.
%
%   Empty signals, invalid sample rates, and signals too short for the chosen
%   detector return an empty events structure rather than an error.
%
% Inputs:
%   signal - Biosignal structure with time, values, and fs fields. time and
%            values must have corresponding samples; fs is in hertz.
%   opts - Optional scalar struct. Start with
%          labkit.biosignal.defaultEcgPeakOptions and change the fields that
%          need tuning for the recording.
%
% Options:
%   method - "qrs-streaming" (default), "pan-tompkins", or "local".
%   polarity - "auto" (default), "positive", "negative", or "absolute".
%              auto chooses the stronger direction; absolute scores either
%              direction by magnitude.
%   minDistanceSec - Minimum accepted peak spacing in seconds. Defaults are
%                    method-specific; see defaultEcgPeakOptions.
%   threshold - Local method only. Explicit score threshold. The default []
%               derives a threshold from thresholdStd.
%   thresholdStd - Local method only. Robust standard-deviation multiplier;
%                  default 3.
%   smoothSec - Local method only. Score smoothing duration; default 0.01
%               seconds.
%   integrationWindowSec - Pan-Tompkins integration duration; default 0.150
%                          seconds.
%   refineSearchSec - Detector-trace search half-width. Defaults are 0.120
%                     seconds for pan-tompkins and 0.090 seconds for
%                     qrs-streaming.
%   rawRefineSearchSec - Final raw-signal search half-width for pan-tompkins
%                        and qrs-streaming. Default 0.020 seconds.
%   baselineWindowSec - qrs-streaming baseline duration; default 0.600
%                       seconds.
%   envelopeWindowSec - qrs-streaming slope-envelope duration; default 0.080
%                       seconds.
%   lookaheadSec - qrs-streaming local-maximum lookahead; default 0.080
%                  seconds.
%   minTemplateScore - qrs-streaming rolling-template correlation threshold;
%                      default 0.45.
%   medianPolarityCorrection - qrs-streaming logical switch for final anchor
%                              polarity correction; default true.
%   medianReviewPeakCount - qrs-streaming review length; default 3 peaks.
%
% Outputs:
%   events - Structure containing one row-aligned entry per detected peak.
%
% Output Fields:
%   type - String scalar "biosignalEvents".
%   index - 1-based sample indices in signal.values.
%   time - Event times copied from signal.time at index.
%   amplitude - Raw signal amplitudes at the accepted indices.
%   score - Method-specific detector score at each event.
%   label - "qrs" for pan-tompkins and qrs-streaming, or "peak" for local.
%   threshold - Final score threshold used by the detector.
%   metadata - Selected method, polarity, minimum spacing, and other
%              method-specific settings used during detection.
%
% Errors:
%   labkit:biosignal:InvalidSignal - signal lacks time, values, or fs.
%   labkit:biosignal:UnsupportedPeakMethod - opts.method is unsupported.
%   labkit:biosignal:UnsupportedPolarity - opts.polarity is unsupported.
%
% Example:
%   fs = 100;
%   time = (0:1/fs:4)';
%   values = zeros(size(time));
%   values(101:100:401) = 1;
%   signal = struct('time', time, 'values', values, 'fs', fs);
%   opts = struct('method', 'local', 'polarity', 'positive', ...
%       'minDistanceSec', 0.5, 'thresholdStd', 1);
%   events = labkit.biosignal.detectEcgPeaks(signal, opts);
%
% See also labkit.biosignal.defaultEcgPeakOptions,
%   labkit.biosignal.segmentByEvents

    if nargin < 2
        opts = struct();
    end
    opts = mergeOptions(labkit.biosignal.defaultEcgPeakOptions(optionValue(opts, 'method', [])), opts);
    events = detectEcgPeaksImpl(signal, opts);
end

function merged = mergeOptions(defaults, overrides)
    merged = defaults;
    if ~isstruct(overrides)
        return;
    end
    fields = fieldnames(overrides);
    for k = 1:numel(fields)
        merged.(fields{k}) = overrides.(fields{k});
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
