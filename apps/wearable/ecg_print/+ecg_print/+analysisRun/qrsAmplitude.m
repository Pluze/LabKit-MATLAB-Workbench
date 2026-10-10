function result = qrsAmplitude(values, rPeaks, fs)
%QRSAMPLITUDE Estimate QRS size with the WFDB NST amplitude convention.
%   result = ecg_print.analysisRun.qrsAmplitude(values, rPeaks, fs) accepts
%   a finite real ECG vector, increasing integer R indices, and positive fs
%   in Hz. Each complete +/-50 ms window contributes its maximum minus
%   minimum. All complete windows are retained; floor(5% of count)
%   at each tail is discarded before averaging. No complete windows gives NaN.
%   result.perBeat contains untrimmed ranges; peakToPeak is their trimmed
%   mean, and equivalentRMS=peakToPeak/sqrt(8) follows the sinusoidal-equivalent
%   power convention S=A^2/8 in https://physionet.org/physiotools/wag/nst-1.htm.
%   Outputs retain input amplitude units. Invalid inputs raise
%   ecg_print:InvalidQRSAmplitudeInput. No IO or optional Toolboxes are used.
%   Using a noisy device ECG instead of annotated normal beats from a clean
%   reference is an estimate, not full NST calibration or morphology fidelity.
%   See also ecg_print.analysisRun.ecgNextAnalysis.
if ~isnumeric(values) || ~isreal(values) || ~isvector(values) || ...
        any(~isfinite(values)) || ~isnumeric(fs) || ~isscalar(fs) || ...
        ~isfinite(fs) || fs <= 0 || ~isnumeric(rPeaks) || ...
        ~isreal(rPeaks) || (~isempty(rPeaks) && ~isvector(rPeaks)) || ...
        any(~isfinite(rPeaks)) || ...
        any(rPeaks ~= fix(rPeaks)) || any(diff(rPeaks) <= 0) || ...
        any(rPeaks < 1 | rPeaks > numel(values))
    error('ecg_print:InvalidQRSAmplitudeInput', ...
        'Supply finite ECG, a positive rate, and increasing R indices.');
end
% WFDB amplitude convention: 50 ms either side,
% and 5 percent trimmed at either tail. This App retains all complete beats.
halfWindow = round(.050 * fs);
trimFraction = .05;
peaks = rPeaks(rPeaks-halfWindow >= 1 & rPeaks+halfWindow <= numel(values));
amplitudes = zeros(numel(peaks), 1);
for k = 1:numel(peaks)
    segment = values(peaks(k)-halfWindow:peaks(k)+halfWindow);
    amplitudes(k) = max(segment)-min(segment);
end
ordered = sort(amplitudes);
trim = floor(trimFraction*numel(ordered));
amplitude = mean(ordered(trim+1:end-trim));
result = struct('perBeat', amplitudes, 'peakToPeak', amplitude, ...
    'equivalentRMS', amplitude/sqrt(8));
end
