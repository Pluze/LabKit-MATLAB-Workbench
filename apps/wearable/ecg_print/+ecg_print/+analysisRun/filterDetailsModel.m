% Expected caller: ECG Print presentation and presentation specifications.
% Characterizes the exact App-owned FIR coefficients used by analysis.
function model = filterDetailsModel(cache, parameters)
empty = emptyResponse();
model = struct("ok", false, "sampleRate", [], "frequency", [], ...
    "analysisBand", [], "detectionBand", [], ...
    "usesAnalysisBand", true, "first", empty, "second", empty, ...
    "cascade", empty);
if isempty(cache.signal)
    return;
end
parameters = completeParameters(parameters);
parameters = ecg_print.analysisRun.sanitizeParameters( ...
    parameters, cache.signal.fs);
model.ok = true;
model.sampleRate = cache.signal.fs;
model.analysisBand = [parameters.lowCut parameters.highCut];
model.usesAnalysisBand = parameters.useAnalysisBandForPeaks;
model.detectionBand = model.analysisBand;
firstDesign = ecg_print.analysisRun.firDesign( ...
    cache.signal.fs, model.analysisBand);
secondDesign = [];
cascadeCoefficients = firstDesign.coefficients;
if ~model.usesAnalysisBand
    model.detectionBand = [parameters.peakLowCut parameters.peakHighCut];
    secondDesign = ecg_print.analysisRun.firDesign( ...
        cache.signal.fs, model.detectionBand);
    cascadeCoefficients = fftConvolution( ...
        firstDesign.coefficients, secondDesign.coefficients);
end
responseLength = max([numel(firstDesign.coefficients), ...
    numel(cascadeCoefficients), 2048]);
transformLength = 2 ^ nextpow2(4 * responseLength);
model.frequency = (0:transformLength/2).' * ...
    cache.signal.fs / transformLength;
model.first = characterize(firstDesign.coefficients, ...
    cache.signal.fs, transformLength);
model.cascade = model.first;
if ~model.usesAnalysisBand
    model.second = characterize(secondDesign.coefficients, ...
        cache.signal.fs, transformLength);
    model.cascade = characterize(cascadeCoefficients, ...
        cache.signal.fs, transformLength);
end
displayIndex = frequencyDisplayIndex(model.frequency, ...
    [model.analysisBand model.detectionBand]);
model.frequency = model.frequency(displayIndex);
model.first = selectFrequency(model.first, displayIndex);
model.cascade = selectFrequency(model.cascade, displayIndex);
if ~model.usesAnalysisBand
    model.second = selectFrequency(model.second, displayIndex);
end
end

function completed = completeParameters(parameters)
completed = ecg_print.initialData().parameters;
names = fieldnames(parameters);
for k = 1:numel(names)
    completed.(names{k}) = parameters.(names{k});
end
end

function response = characterize(coefficients, sampleRate, transformLength)
coefficients = double(coefficients(:));
transfer = fft(coefficients, transformLength, 1);
transfer = transfer(1:transformLength/2+1);
magnitudeDb = 20 * log10(max(abs(transfer), 1e-6));
visible = magnitudeDb > -40;
phase = continuousPassbandPhase(transfer, visible);
frequency = (0:transformLength/2).' * sampleRate / transformLength;
omega = 2 * pi * frequency / sampleRate;
groupDelay = passbandGroupDelay(transfer, omega, visible);
[impulseTime, impulse] = displayImpulse(coefficients, sampleRate);
response = struct("magnitudeDb", magnitudeDb, "phase", phase, ...
    "groupDelay", groupDelay, "impulseTime", impulseTime, ...
    "impulse", impulse, "tapCount", numel(coefficients));
end

function phase = continuousPassbandPhase(transfer, visible)
phase = NaN(size(transfer));
edges = diff([false; visible; false]);
starts = find(edges == 1);
stops = find(edges == -1) - 1;
for k = 1:numel(starts)
    index = starts(k):stops(k);
    if numel(index) < 2
        continue;
    end
    phase(index) = unwrap(angle(transfer(index)));
end
end

function delay = passbandGroupDelay(transfer, omega, visible)
delay = NaN(size(transfer));
edges = diff([false; visible; false]);
starts = find(edges == 1);
stops = find(edges == -1) - 1;
for k = 1:numel(starts)
    index = starts(k):stops(k);
    if numel(index) < 3
        continue;
    end
    localPhase = unwrap(angle(transfer(index)));
    localDelay = -gradient(localPhase) ./ gradient(omega(index));
    localDelay([1 end]) = NaN;
    delay(index) = localDelay;
end
end

function [time, values] = displayImpulse(coefficients, sampleRate)
time = (0:numel(coefficients)-1).' / sampleRate;
index = (1:numel(coefficients)).';
maximumPoints = 2401;
if numel(index) > maximumPoints
    stride = ceil(numel(index) / maximumPoints);
    center = (numel(index) + 1) / 2;
    index = unique([index(1:stride:end); center; index(end)]);
end
time = time(index);
values = coefficients(index);
end

function values = fftConvolution(first, second)
outputLength = numel(first) + numel(second) - 1;
transformLength = 2 ^ nextpow2(outputLength);
values = real(ifft( ...
    fft(first, transformLength) .* fft(second, transformLength)));
values = values(1:outputLength);
end

function index = frequencyDisplayIndex(frequency, bandEdges)
maximumPoints = 8193;
if numel(frequency) <= maximumPoints
    index = (1:numel(frequency)).';
    return;
end
stride = ceil(numel(frequency) / maximumPoints);
index = (1:stride:numel(frequency)).';
edgeNeighbors = zeros(3 * numel(bandEdges), 1);
for k = 1:numel(bandEdges)
    [~, nearest] = min(abs(frequency - bandEdges(k)));
    edgeNeighbors(3 * k - 2:3 * k) = [ ...
        max(1, nearest - 1); nearest; ...
        min(numel(frequency), nearest + 1)];
end
index = unique([index; edgeNeighbors; numel(frequency)]);
end

function response = selectFrequency(response, index)
response.magnitudeDb = response.magnitudeDb(index);
response.phase = response.phase(index);
response.groupDelay = response.groupDelay(index);
end

function response = emptyResponse()
response = struct("magnitudeDb", [], "phase", [], ...
    "groupDelay", [], "impulseTime", [], "impulse", [], ...
    "tapCount", 0);
end
