function [values, edge] = prepare(signal, band)
% The optional centered Blackman FIR has no phase delay. A quarter-second
% half-support resolves the low-frequency transition and sets the edge margin.
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
        error("emg_review:BelowNyquist", "The 5–500 Hz band requires a sample rate above 1000 Hz. Choose As recorded.");
    end
    halfSupportSeconds = 0.25;
    edge = round(halfSupportSeconds * fs);
    if numel(values) <= 2 * edge
        error("emg_review:ShortRecording", "The recording is too short for the filter edge margins.");
    end
    lag = (-edge:edge).';
    b = zeros(size(lag));
    nonzero = lag ~= 0;
    b(nonzero) = (sin(2*pi*passband(2)*lag(nonzero)/fs) - ...
        sin(2*pi*passband(1)*lag(nonzero)/fs)) ./ (pi*lag(nonzero));
    b(~nonzero) = 2 * diff(passband) / fs;
    b = b .* (0.42 + 0.5*cos(pi*lag/edge) + 0.08*cos(2*pi*lag/edge));
    values = conv(values, b, 'same');
end
