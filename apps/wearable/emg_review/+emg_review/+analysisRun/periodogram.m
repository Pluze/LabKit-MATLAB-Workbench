function [frequency, density] = periodogram(values, fs)
% One-sided, energy-normalized PSD with the reference periodic Hann taper.
    count = size(values, 1);
    taper = 0.5 - 0.5*cos(2*pi*(0:count - 1).'/count);
    spectrum = fft((values - mean(values, 1)) .* taper, [], 1);
    half = floor(count / 2) + 1;
    frequency = (0:half - 1).' * (fs / count);
    density = abs(spectrum(1:half, :)).^2 / (fs * sum(taper.^2));
    lastInterior = half - (mod(count, 2) == 0);
    density(2:lastInterior, :) = 2 * density(2:lastInterior, :);
end
