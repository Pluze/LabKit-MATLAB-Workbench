% Expected callers: ECG Print analysis and filter-detail modeling.
function design = firDesign(sampleRate, requestedBand)
%FIRDESIGN Design the App-owned stable linear-phase ECG FIR.
% The Hamming-windowed sinc has about four seconds of odd-length taps,
% bounded at 8001 taps. A full [0 Fs/2] band is represented by one unity
% tap so the default remains an exact bypass.
sampleRate = double(sampleRate);
nyquist = 0.5 * sampleRate;
band = sort(double(requestedBand(:).'));
band = [max(0, band(1)) min(nyquist, band(end))];
if band(1) <= 0 && band(2) >= nyquist
    design = makeDesign(sampleRate, band, 1, true);
    return;
end
maximumTapCount = 8001;
minimumTapCount = 129;
tapCount = min(maximumTapCount, max(minimumTapCount, ...
    2 * floor(2 * sampleRate) + 1));
halfOrder = (tapCount - 1) / 2;
n = (-halfOrder:halfOrder).';
window = 0.54 - 0.46 * cos(2 * pi * (0:tapCount-1).' / ...
    (tapCount - 1));
upper = idealLowpass(band(2), sampleRate, n);
lower = idealLowpass(band(1), sampleRate, n);
coefficients = (upper - lower) .* window;
referenceHz = passbandReference(band, nyquist);
phase = exp(-1i * 2 * pi * referenceHz / sampleRate * ...
    (0:tapCount-1).');
gain = abs(sum(coefficients .* phase));
if isfinite(gain) && gain > eps
    coefficients = coefficients / gain;
end
design = makeDesign(sampleRate, band, coefficients, false);
end

function values = idealLowpass(cutoff, sampleRate, n)
normalized = 2 * cutoff / sampleRate;
argument = normalized * n;
values = normalized * ones(size(n));
nonzero = argument ~= 0;
values(nonzero) = normalized * sin(pi * argument(nonzero)) ./ ...
    (pi * argument(nonzero));
end

function frequency = passbandReference(band, nyquist)
if band(1) <= 0
    frequency = 0;
elseif band(2) >= nyquist
    frequency = 0.5 * (band(1) + nyquist);
else
    frequency = 0.5 * sum(band);
end
end

function design = makeDesign(sampleRate, band, coefficients, bypass)
design = struct("sampleRate", sampleRate, "band", band, ...
    "coefficients", double(coefficients(:)), ...
    "order", numel(coefficients) - 1, ...
    "groupDelaySamples", 0.5 * (numel(coefficients) - 1), ...
    "window", "Hamming", "bypass", bypass);
end
