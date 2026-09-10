function samples = makeSamples(batch, configuration, timing)
% Convert one NI buffer fetch into MATLAB-native facade samples.
count = numel(batch.Values);
samples = repmat(emptySample(configuration), count, 1);
for index = 1:count
    sequence = batch.FirstSequence + index - 1;
    elapsed_s = timing.MeasurementPeriod_s + ...
        (sequence - 1) * timing.RequestedPeriod_s;
    samples(index).Valid = isfinite(batch.Values(index));
    samples(index).Value = batch.Values(index);
    samples(index).Sequence = sequence;
    samples(index).Elapsed_s = elapsed_s;
    samples(index).TimestampUTC = timing.StartedAtUTC + seconds(elapsed_s);
    samples(index).ReceivedAtUTC = batch.ReceivedAtUTC;
    samples(index).TimeUncertainty_s = max( ...
        timing.RequestedPeriod_s, timing.StartUncertainty_s);
    if ~samples(index).Valid
        samples(index).FailureStatus = "nonfinite_reading";
    end
end
end

function sample = emptySample(configuration)
sample = struct("Valid", false, "Value", NaN, ...
    "Unit", configuration.Unit, "Mode", configuration.Mode, ...
    "Range", configuration.Range, "Digits", configuration.Digits, ...
    "Sequence", 0, "Elapsed_s", NaN, ...
    "TimestampUTC", NaT(1, "TimeZone", "UTC"), ...
    "ReceivedAtUTC", NaT(1, "TimeZone", "UTC"), ...
    "TimeUncertainty_s", NaN, "FailureStatus", "");
end
