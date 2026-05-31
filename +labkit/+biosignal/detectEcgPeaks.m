function events = detectEcgPeaks(signal, opts)
%DETECTECGPEAKS Detect ECG/QRS peaks as event anchors.
%
% Usage:
%   events = labkit.biosignal.detectEcgPeaks(signal);
%   opts = labkit.biosignal.defaultEcgPeakOptions("pan-tompkins");
%   opts.minDistanceSec = 0.35;
%   events = labkit.biosignal.detectEcgPeaks(signal, opts);
%
% Inputs:
%   signal - biosignal signal struct with time, values, and fs fields.
%   opts - optional struct. Start from defaultEcgPeakOptions(method) and
%          override fields rather than hand-writing all options.
%
% Options:
%   method - "qrs-streaming" (default), "pan-tompkins", or "local".
%   polarity - "auto" (default), "positive", "negative", or "absolute".
%   minDistanceSec - minimum accepted peak spacing in seconds.
%   thresholdStd, smoothSec - local method options.
%   integrationWindowSec, refineSearchSec - Pan-Tompkins method options.
%   baselineWindowSec, envelopeWindowSec, lookaheadSec, refineSearchSec,
%       minTemplateScore - qrs-streaming method options.
%
% Output:
%   events - struct with index, time, amplitude, score, label, threshold,
%            and metadata.method.

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
