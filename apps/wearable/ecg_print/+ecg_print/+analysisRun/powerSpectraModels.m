function models = powerSpectraModels(cache, usesPrimaryBand)
%POWERSPECTRAMODELS Build three analysis-stage power-spectrum models.
%
% Usage:
%   models = ecg_print.analysisRun.powerSpectraModels(cache)
%   models = ecg_print.analysisRun.powerSpectraModels(cache, usesPrimaryBand)
%
% Description:
%   Estimates one-sided Welch power spectral density (PSD) for the analyzed
%   ROI at three stages: the raw signal, the primary analysis-filter output,
%   and the signal used for peak detection. Each segment is mean-centered,
%   multiplied by a symmetric Hamming window, and overlapped by 50 percent.
%   Segment length is limited to 8192 samples so runtime and memory remain
%   bounded for long recordings. The returned decibel values use a reference
%   of one signal-unit squared per hertz and are clipped 120 dB below the
%   largest displayed density; linear PSD values are retained without that
%   display clipping.
%
% Inputs:
%   cache - Scalar ECG Print cache. workingSignal, filteredSignal, and
%       peakDetectionSignal are expected to contain real sample vectors and a
%       positive sample rate in hertz. Missing or empty stages produce an
%       empty model rather than a fabricated spectrum.
%   usesPrimaryBand - Optional logical scalar declaring that the peak
%       detector reuses filteredSignal. When supplied true, the third model
%       reuses the second PSD calculation. When omitted, equal primary and
%       detector samples are treated as the same input.
%
% Outputs:
%   models - Three-element structure array with axisId, title, frequency in
%       hertz, powerDensity in signal-unit squared per hertz, powerDb,
%       yLabel, segmentLength, and segmentCount. ok is true when a spectrum
%       could be estimated from at least one complete finite segment.

maximumSegmentLength = 8192;
stageFields = ["workingSignal" "filteredSignal" "peakDetectionSignal"];
axisIds = ["rawSpectrum" "analysisSpectrum" "peakSpectrum"];
titles = ["Raw signal", "Primary band-pass output", ...
    "Peak-detection band output"];
empty = struct("axisId", "", "ok", false, "title", "", ...
    "frequency", [], "powerDensity", [], "powerDb", [], ...
    "yLabel", "", "segmentLength", 0, "segmentCount", 0);
models = repmat(empty, 1, numel(stageFields));
if nargin < 2
    usesPrimaryBand = false;
elseif ~islogical(usesPrimaryBand) || ~isscalar(usesPrimaryBand)
    error("ecg_print:InvalidSpectrumStage", ...
        "usesPrimaryBand must be a logical scalar.");
end
if nargin < 2 && isfield(cache, "filteredSignal") && ...
        isfield(cache, "peakDetectionSignal") && ...
        ~isempty(cache.filteredSignal) && ...
        ~isempty(cache.peakDetectionSignal)
    usesPrimaryBand = isequaln(cache.filteredSignal.values, ...
        cache.peakDetectionSignal.values);
end
if usesPrimaryBand
    titles(3) = "Peak-detection input · primary band reused";
end
for k = 1:numel(stageFields)
    models(k).axisId = axisIds(k);
    models(k).title = titles(k);
    if ~isfield(cache, stageFields(k)) || isempty(cache.(stageFields(k)))
        continue;
    end
    signal = cache.(stageFields(k));
    unit = ecg_print.analysisRun.signalUnit(signal);
    models(k).yLabel = "PSD (dB re 1 " + unit + "^2/Hz)";
    if k == 3 && usesPrimaryBand && models(2).ok
        models(k).frequency = models(2).frequency;
        models(k).powerDensity = models(2).powerDensity;
        models(k).powerDb = models(2).powerDb;
        models(k).segmentLength = models(2).segmentLength;
        models(k).segmentCount = models(2).segmentCount;
        models(k).ok = true;
        continue;
    end
    [frequency, density, segmentLength, segmentCount] = ...
        estimateWelch(signal.values, signal.fs, maximumSegmentLength);
    models(k).frequency = frequency;
    models(k).powerDensity = density;
    models(k).segmentLength = segmentLength;
    models(k).segmentCount = segmentCount;
    if segmentCount == 0
        continue;
    end
    models(k).powerDb = displayDecibels(density);
    models(k).ok = true;
end
end

function [frequency, density, segmentLength, segmentCount] = ...
        estimateWelch(values, sampleRate, maximumSegmentLength)
values = double(values(:));
if ~isreal(values) || ~isscalar(sampleRate) || ...
        ~isfinite(sampleRate) || sampleRate <= 0
    error("ecg_print:InvalidSpectrumInput", ...
        "Power spectra require a real signal and a positive sample rate.");
end
segmentLength = min(numel(values), maximumSegmentLength);
frequency = zeros(0, 1);
density = zeros(0, 1);
segmentCount = 0;
if segmentLength < 2
    return;
end
sampleIndex = (0:segmentLength-1).';
window = 0.54 - 0.46 .* cos(2 .* pi .* sampleIndex ./ ...
    (segmentLength - 1));
windowEnergy = sum(window .^ 2);
transformLength = 2 ^ nextpow2(segmentLength);
oneSidedLength = transformLength / 2 + 1;
density = zeros(oneSidedLength, 1);
step = max(1, floor(segmentLength / 2));
starts = 1:step:(numel(values) - segmentLength + 1);
for startIndex = starts
    segment = values(startIndex:startIndex + segmentLength - 1);
    if ~all(isfinite(segment))
        continue;
    end
    segment = (segment - mean(segment)) .* window;
    transform = fft(segment, transformLength);
    segmentDensity = abs(transform(1:oneSidedLength)) .^ 2 ./ ...
        (sampleRate .* windowEnergy);
    segmentDensity(2:end-1) = 2 .* segmentDensity(2:end-1);
    density = density + segmentDensity;
    segmentCount = segmentCount + 1;
end
frequency = (0:oneSidedLength-1).' .* sampleRate ./ transformLength;
if segmentCount == 0
    density = zeros(0, 1);
    frequency = zeros(0, 1);
    return;
end
density = density ./ segmentCount;
end

function values = displayDecibels(density)
maximumDensity = max(density);
if maximumDensity > 0
    displayFloor = maximumDensity .* 1e-12;
else
    displayFloor = realmin("double");
end
values = 10 .* log10(max(density, displayFloor));
end
