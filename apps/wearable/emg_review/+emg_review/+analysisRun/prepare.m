function [values, edge] = prepare(signal, band)
% Centered Blackman FIR matches the 501-tap, 2 kHz reference. Retain the
% same time support at other rates and exclude the reference edge margin.
    fs = signal.fs;
    values = signal.values(:);
    [choices, passband] = emg_review.analysisRun.bands();
    if ~isscalar(fs) || ~isfinite(fs) || fs <= 0 || ...
            numel(values) < 2 || any(~isfinite(values))
        error("emg_review:InvalidSignal", "Choose a recording with a finite sample rate and at least two finite samples.");
    end
    edge = 0;
    if band == choices(1)
        return;
    end
    if band ~= choices(2)
        error("emg_review:InvalidBand", "Choose a supported measurement band.");
    end
    if fs <= 2 * passband(2)
        error("emg_review:BelowNyquist", "The 20–450 Hz band requires a sample rate above 900 Hz. Choose As recorded.");
    end
    halfSupportSeconds = 0.125;
    edgeSeconds = 0.25;
    edge = round(edgeSeconds * fs);
    if numel(values) <= 2 * edge
        error("emg_review:ShortRecording", "The recording is too short for the filter edge margins.");
    end
    halfLength = round(halfSupportSeconds * fs);
    lag = (-halfLength:halfLength).';
    b = zeros(size(lag));
    nonzero = lag ~= 0;
    b(nonzero) = (sin(2*pi*passband(2)*lag(nonzero)/fs) - ...
        sin(2*pi*passband(1)*lag(nonzero)/fs)) ./ (pi*lag(nonzero));
    b(~nonzero) = 2 * diff(passband) / fs;
    b = b .* (0.42 + 0.5*cos(pi*lag/halfLength) + 0.08*cos(2*pi*lag/halfLength));
    values = conv(values, b, 'same');
end
