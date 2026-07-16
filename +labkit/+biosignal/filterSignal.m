function filtered = filterSignal(signal, spec)
%FILTERSIGNAL Apply a zero-phase FFT-domain filter to a biosignal.
%
% Usage:
%   filtered = labkit.biosignal.filterSignal(signal)
%   filtered = labkit.biosignal.filterSignal(signal, spec)
%
% Description:
%   Applies an ideal frequency mask in the discrete Fourier domain and uses
%   an inverse transform to return a zero-phase filtered waveform. Low-pass
%   and band-pass filtering restore the input mean after filtering;
%   high-pass filtering does not. Missing samples are filled before the
%   transform, so filtered.values is finite when the input contains enough
%   finite data for interpolation.
%
%   Reflect edge mode extrapolates both ends of the waveform before applying
%   the FFT and removes the padding afterward. A cosine taper is applied only
%   to the outer padded samples. This reduces wraparound artifacts without
%   changing the length or time axis of the signal. Use edgeMode "none" when
%   the unpadded periodic FFT behavior is required.
%
% Inputs:
%   signal - Biosignal structure with values, fs, and metadata fields. fs is
%            the sample rate in hertz.
%   spec - Optional scalar struct containing the fields listed below.
%
% Options:
%   type - "bandpass" (default), "lowpass", "highpass", "none", or "off".
%          The latter two skip frequency masking but still fill missing data.
%   cutoffHz - Scalar cutoff for low-pass or high-pass filtering, or a
%              two-element [low high] band for band-pass filtering. The
%              default is [0.5 40] Hz. Empty or nonfinite values skip
%              filtering and return the filled waveform.
%   edgeMode - "reflect" (default) or "none". The aliases "reflection",
%              "symmetric", "pad", and "padded" select reflection;
%              "off" and "raw" select no padding.
%   edgePadSec - Nonnegative padding duration in seconds. By default,
%                band-pass and high-pass filters use three periods of the
%                lowest cutoff, limited to 0.5 through 5 seconds. Other
%                filters use 1 second. Padding cannot exceed half the
%                available signal minus one sample.
%   edgeTaperSec - Nonnegative duration of the outer padding taper. The
%                  default is 1 second.
%
% Outputs:
%   filtered - Copy of signal with filtered values. All other signal fields
%              are preserved, and metadata.filter records spec exactly as
%              supplied by the caller.
%
% Errors:
%   labkit:biosignal:InvalidSignal - signal lacks values or fs.
%   labkit:biosignal:UnsupportedFilter - type is not supported.
%   labkit:biosignal:UnsupportedFilterEdgeMode - edgeMode is not supported.
%
% Example:
%   fs = 100;
%   time = (0:1/fs:2)';
%   values = sin(2*pi*2*time) + 0.2*sin(2*pi*30*time);
%   signal = struct('time', time, 'values', values, 'fs', fs, ...
%       'metadata', struct());
%   filtered = labkit.biosignal.filterSignal(signal, ...
%       struct('type', 'lowpass', 'cutoffHz', 10));

    if nargin < 2
        spec = struct();
    end
    validateSignal(signal);

    filtered = signal;
    x = fillVectorMissing(double(signal.values(:)));
    fs = double(signal.fs);
    if isempty(x) || ~isfinite(fs) || fs <= 0
        filtered.values = x;
        filtered.metadata.filter = spec;
        return;
    end

    type = lower(string(optionValue(spec, 'type', 'bandpass')));
    cutoff = double(optionValue(spec, 'cutoffHz', [0.5 40]));
    if isempty(cutoff) || any(~isfinite(cutoff))
        filtered.values = x;
        filtered.metadata.filter = spec;
        return;
    end

    y = x - mean(x, 'omitnan');
    n = numel(y);
    [work, cropStart] = prepareFilterInput(y, fs, cutoff, spec, type);
    freq = (0:numel(work)-1).' * fs / numel(work);
    foldedFreq = min(freq, fs - freq);

    switch type
        case "bandpass"
            cutoff = sort(cutoff(:));
            mask = foldedFreq >= cutoff(1) & foldedFreq <= cutoff(end);
        case "lowpass"
            mask = foldedFreq <= cutoff(1);
        case "highpass"
            mask = foldedFreq >= cutoff(1);
        case {"none", "off"}
            mask = true(size(foldedFreq));
        otherwise
            error('labkit:biosignal:UnsupportedFilter', ...
                'Unsupported filter type: %s.', type);
    end

    values = real(ifft(fft(work) .* mask));
    values = values(cropStart:cropStart+n-1);
    if type ~= "highpass"
        values = values + mean(x, 'omitnan');
    end
    filtered.values = values;
    filtered.metadata.filter = spec;
end

function [work, cropStart] = prepareFilterInput(y, fs, cutoff, spec, type)
    work = y(:);
    cropStart = 1;
    if any(type == ["none", "off"])
        return;
    end
    edgeMode = normalizeEdgeMode(optionValue(spec, 'edgeMode', 'reflect'));
    if edgeMode == "none" || numel(work) < 4
        return;
    end

    padSec = optionValue(spec, 'edgePadSec', []);
    if isempty(padSec)
        padSec = defaultEdgePadSec(cutoff, type);
    end
    padN = max(0, round(double(padSec) * fs));
    padN = min(padN, floor((numel(work) - 1) / 2));
    if padN < 1
        return;
    end

    leftPad = 2 * work(1) - flipud(work(2:padN+1));
    rightPad = 2 * work(end) - flipud(work(end-padN:end-1));
    work = [leftPad; work; rightPad];
    cropStart = padN + 1;

    taperSec = double(optionValue(spec, 'edgeTaperSec', 1));
    taperN = min([padN, round(max(0, taperSec) * fs), floor((numel(work) - 1) / 2)]);
    if taperN > 1
        ramp = 0.5 - 0.5 * cos(pi * (0:taperN-1).' / (taperN - 1));
        work(1:taperN) = work(1:taperN) .* ramp;
        work(end-taperN+1:end) = work(end-taperN+1:end) .* flipud(ramp);
    end
end

function mode = normalizeEdgeMode(value)
    mode = lower(strtrim(string(value)));
    switch mode
        case {"", "reflect", "reflection", "symmetric", "pad", "padded"}
            mode = "reflect";
        case {"none", "off", "raw"}
            mode = "none";
        otherwise
            error('labkit:biosignal:UnsupportedFilterEdgeMode', ...
                'Unsupported filter edgeMode: %s.', mode);
    end
end

function padSec = defaultEdgePadSec(cutoff, type)
    cutoff = sort(double(cutoff(:)));
    switch type
        case {"bandpass", "highpass"}
            lowCut = cutoff(1);
            if isfinite(lowCut) && lowCut > 0
                padSec = min(5, max(0.5, 3 / lowCut));
            else
                padSec = 1;
            end
        otherwise
            padSec = 1;
    end
end

function validateSignal(signal)
    assert(isstruct(signal) && isfield(signal, 'values') && isfield(signal, 'fs'), ...
        'labkit:biosignal:InvalidSignal', ...
        'Signal must contain values and fs fields.');
end
