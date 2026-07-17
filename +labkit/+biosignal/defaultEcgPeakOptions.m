function opts = defaultEcgPeakOptions(method)
%DEFAULTECGPEAKOPTIONS Return documented defaults for ECG/QRS peak detection.
%
% Usage:
%   opts = labkit.biosignal.defaultEcgPeakOptions()
%   opts = labkit.biosignal.defaultEcgPeakOptions(method)
%
% Description:
%   Returns a complete starting options structure for one ECG peak detector.
%   Modify only the fields needed for a recording, then pass the structure to
%   labkit.biosignal.detectEcgPeaks. Fields that do not apply to the selected
%   method are omitted, which makes saved settings easier to interpret.
%
% Inputs:
%   method - Optional character vector or scalar string. Canonical values are
%            "qrs-streaming" (default), "pan-tompkins", and "local".
%            Common spellings such as "streaming", "pantompkin", and
%            "simple" are accepted and normalized to a canonical value.
%
% Outputs:
%   opts - Scalar structure containing the selected method and its defaults.
%
% Common Options:
%   method - Canonical detector name.
%   polarity - Peak direction: "auto", "positive", "negative", or
%              "absolute". The default is "auto".
%   minDistanceSec - Minimum interval between accepted peaks. The default is
%                    0.25 seconds for qrs-streaming and pan-tompkins, and
%                    0.05 seconds for local.
%
% Local Options:
%   thresholdStd - Number of robust standard deviations above the median
%                  score used as the automatic threshold. Default 3.
%   smoothSec - Moving-average duration applied to the peak score. Default
%               0.01 seconds.
%
% Pan-Tompkins Options:
%   integrationWindowSec - Moving integration duration for squared QRS-band
%                          slope energy. Default 0.150 seconds.
%   refineSearchSec - Half-width used to move an energy candidate to the
%                     nearest peak in the detector trace. Default 0.120
%                     seconds.
%   rawRefineSearchSec - Half-width for the final move to a peak in the raw
%                        signal. Default 0.020 seconds.
%
% Streaming QRS Options:
%   baselineWindowSec - Causal moving-baseline duration. Default 0.600
%                       seconds.
%   envelopeWindowSec - Causal slope-envelope duration. Default 0.080
%                       seconds.
%   lookaheadSec - Forward interval used to confirm a local envelope maximum.
%                  Default 0.080 seconds.
%   refineSearchSec - Half-width used to move a candidate from the envelope
%                     to the baseline-corrected signal. Default 0.090 seconds.
%   rawRefineSearchSec - Half-width for the final move to a raw-signal peak.
%                        Default 0.020 seconds.
%   minTemplateScore - Minimum correlation with the rolling QRS template once
%                      at least four templates are available. Default 0.45.
%   medianPolarityCorrection - Logical value that enables a final correction
%                              of isolated opposite-polarity anchors. Default
%                              true.
%   medianReviewPeakCount - Number of accepted peaks used by the polarity
%                           review. Default 3.
%
% Errors:
%   labkit:biosignal:UnsupportedPeakMethod - method cannot be normalized to
%                                           a supported detector.
%
% Example:
%   opts = labkit.biosignal.defaultEcgPeakOptions("pan-tompkins");
%   opts.minDistanceSec = 0.35;
%
% See also labkit.biosignal.detectEcgPeaks

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
            opts.rawRefineSearchSec = 0.020;
        otherwise
            opts.minDistanceSec = 0.25;
            opts.baselineWindowSec = 0.600;
            opts.envelopeWindowSec = 0.080;
            opts.lookaheadSec = 0.080;
            opts.refineSearchSec = 0.090;
            opts.rawRefineSearchSec = 0.020;
            opts.minTemplateScore = 0.45;
            opts.medianPolarityCorrection = true;
            opts.medianReviewPeakCount = 3;
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
