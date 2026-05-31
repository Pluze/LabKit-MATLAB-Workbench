function filtered = filterSignal(signal, spec)
%FILTERSIGNAL Apply a zero-phase FFT-domain filter to a biosignal.

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
    freq = (0:n-1).' * fs / n;
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

    values = real(ifft(fft(y) .* mask));
    if type ~= "highpass"
        values = values + mean(x, 'omitnan');
    end
    filtered.values = values;
    filtered.metadata.filter = spec;
end

function validateSignal(signal)
    assert(isstruct(signal) && isfield(signal, 'values') && isfield(signal, 'fs'), ...
        'labkit:biosignal:InvalidSignal', ...
        'Signal must contain values and fs fields.');
end
