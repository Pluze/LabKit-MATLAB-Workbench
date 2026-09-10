function pollSampler(state)
% Drain available NI-DMM readings without blocking the MATLAB event loop.
if ~state("active")
    return;
end
try
    backend = state("backend");
    batch = backend.fetchAvailable();
    if isempty(batch.Values)
        return;
    end
    samples = makeSamples(batch, state("configuration"), state("timing"));
    callback = state("onSamples");
    callback(state("connection"), samples);
catch cause
    state("failure") = cause;
    state("active") = false;
    timerValue = state("timer");
    if isvalid(timerValue)
        stop(timerValue);
    end
    sample = makeFailureSample(state("configuration"), cause);
    try
        callback = state("onSamples");
        callback(state("connection"), sample);
    catch
    end
end
end

function sample = makeFailureSample(configuration, cause)
sample = struct("Valid", false, "Value", NaN, ...
    "Unit", configuration.Unit, "Mode", configuration.Mode, ...
    "Range", configuration.Range, "Digits", configuration.Digits, ...
    "Sequence", 0, "Elapsed_s", NaN, ...
    "TimestampUTC", datetime("now", "TimeZone", "UTC"), ...
    "ReceivedAtUTC", datetime("now", "TimeZone", "UTC"), ...
    "TimeUncertainty_s", NaN, ...
    "FailureStatus", string(cause.identifier));
end
