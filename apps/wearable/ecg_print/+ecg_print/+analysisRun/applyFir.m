% Expected caller: ECG Print's primary and peak-location filter stages.
function filtered = applyFir(signal, design)
%APPLYFIR Apply a stable FIR with reflection and delay compensation.
filtered = signal;
metadata = struct("type", "fir-bandpass", ...
    "cutoffHz", design.band, "order", design.order, ...
    "window", design.window, "zeroPhaseAligned", true);
if design.bypass
    metadata.type = "none";
    filtered.metadata.filter = metadata;
    return;
end
x = fillmissing(double(signal.values(:)), "linear", ...
    "EndValues", "nearest");
if isempty(x)
    filtered.values = x;
    filtered.metadata.filter = metadata;
    return;
end
halfOrder = design.groupDelaySamples;
padCount = min(halfOrder, numel(x) - 1);
if padCount > 0
    left = 2 * x(1) - flipud(x(2:padCount+1));
    right = 2 * x(end) - flipud(x(end-padCount:end-1));
    work = [left; x; right];
else
    work = x;
end
fullLength = numel(work) + numel(design.coefficients) - 1;
transformLength = 2 ^ nextpow2(fullLength);
convolution = real(ifft( ...
    fft(work, transformLength) .* ...
    fft(design.coefficients, transformLength)));
startIndex = halfOrder + 1;
aligned = convolution(startIndex:startIndex + numel(work) - 1);
filtered.values = aligned(padCount + (1:numel(x)));
filtered.metadata.filter = metadata;
end
