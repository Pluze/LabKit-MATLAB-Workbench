function filtered = filterSignal(signal, spec)
%FILTERSIGNAL Apply a zero-phase FFT-domain filter to a biosignal.
%
% Usage:
%   filtered = labkit.biosignal.filterSignal(signal);
%   filtered = labkit.biosignal.filterSignal(signal, ...
%       struct('type', 'bandpass', 'cutoffHz', [0.5 40]));
%
% Inputs:
%   signal - biosignal signal struct with values and fs fields.
%   spec - optional struct.
%
% Options:
%   type - "bandpass" (default), "lowpass", "highpass", "none", or "off".
%   cutoffHz - scalar for low/high pass or [low high] for bandpass.
%   edgeMode - "reflect" (default) or "none". Reflect mode pads both ends
%              before FFT filtering, then crops back to the original length.
%   edgePadSec - positive scalar padding seconds. Default is derived from
%                the low cutoff and capped at 5 seconds.
%   edgeTaperSec - positive scalar seconds used to taper only the padded
%                  edges toward zero before FFT filtering. Default 1 second.
%
% Output:
%   filtered - signal struct preserving metadata and replacing values.

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
