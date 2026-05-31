function events = detectEcgPeaks(signal, opts)
%DETECTECGPEAKS Detect ECG/QRS peaks as event anchors.
%
% Method options:
%   "pan-tompkins"  QRS band, derivative energy, moving integration, adaptive threshold.
%   "qrs-streaming" causal envelope, adaptive threshold, refractory, template QC.
%   "local"         simple ECG-oriented local peak detector for baseline comparison.

    if nargin < 2
        opts = struct();
    end
    events = detectEcgPeaksImpl(signal, opts);
end
