function opts = defaultEcgPeakOptions(method)
%DEFAULTECGPEAKOPTIONS Return documented defaults for ECG/QRS peak detection.
%
% Usage:
%   opts = labkit.biosignal.defaultEcgPeakOptions();
%   opts = labkit.biosignal.defaultEcgPeakOptions("pan-tompkins");
%   opts.minDistanceSec = 0.35;
%   events = labkit.biosignal.detectEcgPeaks(signal, opts);
%
% Inputs:
%   method - Optional char/string. Legal values are "qrs-streaming",
%            "pan-tompkins", and "local". Default is "qrs-streaming".
%
% Returned options:
%   method - string, selected detector method.
%   polarity - "auto", "positive", "negative", or "absolute"; default "auto".
%   minDistanceSec - positive scalar seconds between accepted ECG peaks.
%   thresholdStd - local method only, robust-threshold multiplier; default 3.
%   smoothSec - local method only, moving-average score smoothing; default 0.01.
%   integrationWindowSec - Pan-Tompkins method only; default 0.150.
%   refineSearchSec - Pan-Tompkins/streaming peak snap half-window; defaults
%                     0.120 and 0.090 respectively.
%   baselineWindowSec - streaming method only, causal baseline window; default 0.600.
%   envelopeWindowSec - streaming method only, causal slope-envelope window; default 0.080.
%   lookaheadSec - streaming method only, local maximum lookahead; default 0.080.
%   minTemplateScore - streaming method only, rolling template QC threshold; default 0.45.

    if nargin < 1 || isempty(method)
        method = "qrs-streaming";
    end

    method = normalizeMethod(method);
    opts = struct();
    opts.method = method;
    opts.polarity = "auto";

    switch method
        case "local"
            opts.minDistanceSec = 0.05;
            opts.thresholdStd = 3;
            opts.smoothSec = 0.01;
        case "pan-tompkins"
            opts.minDistanceSec = 0.25;
            opts.integrationWindowSec = 0.150;
            opts.refineSearchSec = 0.120;
        otherwise
            opts.minDistanceSec = 0.25;
            opts.baselineWindowSec = 0.600;
            opts.envelopeWindowSec = 0.080;
            opts.lookaheadSec = 0.080;
            opts.refineSearchSec = 0.090;
            opts.minTemplateScore = 0.45;
    end
end

function method = normalizeMethod(value)
    method = lower(strtrim(string(value)));
    method = regexprep(method, '[\s\-/+_]+', '-');
    switch method
        case {"", "auto", "qrs-streaming", "streaming", "streaming-qrs"}
            method = "qrs-streaming";
        case {"pan-tompkins", "pantompkin", "pan-tompkin", "pan-tompkins-qrs"}
            method = "pan-tompkins";
        case {"local", "local-peaks", "simple", "simple-local"}
            method = "local";
        otherwise
            error('labkit:biosignal:UnsupportedPeakMethod', ...
                'Unsupported ECG peak detection method: %s.', char(string(value)));
    end
end
