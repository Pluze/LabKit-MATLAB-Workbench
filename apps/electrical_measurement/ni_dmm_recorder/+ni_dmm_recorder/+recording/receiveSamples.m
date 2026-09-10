function receiveSamples(box, buffer, context, connection, samples)
%RECEIVESAMPLES Retain one delivered NI-DMM batch and coalesce presentation.
box("connection") = connection;
if string(box("connection").Type) ~= "labkit.nidmm.connection"
    error("ni_dmm_recorder:InvalidConnection", ...
        "NI-DMM sample callback received an invalid connection.");
end
for index = 1:numel(samples)
    sample = samples(index);
    buffer("sampleCount") = buffer("sampleCount") + 1;
    if sample.Valid
        buffer("validCount") = buffer("validCount") + 1;
        buffer("lastValue") = sample.Value;
        buffer("lastUnit") = sample.Unit;
        buffer("lastFailure") = "";
        buffer = appendPlot(buffer, sample.TimestampUTC, ...
            sample.Elapsed_s, sample.Value);
    else
        buffer("invalidCount") = buffer("invalidCount") + 1;
        buffer("lastFailure") = sample.FailureStatus;
    end
    buffer("timestampUTC") = [buffer("timestampUTC"); sample.TimestampUTC];
    buffer("receivedAtUTC") = [buffer("receivedAtUTC"); sample.ReceivedAtUTC];
    buffer("elapsed_s") = [buffer("elapsed_s"); sample.Elapsed_s];
    buffer("value") = [buffer("value"); sample.Value];
    buffer("valid") = [buffer("valid"); sample.Valid];
    buffer("timeUncertainty_s") = [buffer("timeUncertainty_s"); ...
        sample.TimeUncertainty_s];
    if isfinite(sample.Elapsed_s)
        buffer("lastElapsed_s") = sample.Elapsed_s;
    end
end
postRefreshIfDue(buffer, context);
end

function buffer = appendPlot(buffer, timestampUTC, elapsed_s, value)
time = [buffer("plotTime_s"); elapsed_s];
values = [buffer("plotValue"); value];
timestamps = [buffer("plotTimestampUTC"); timestampUTC];
first = max(1, numel(time) - 2000 + 1);
buffer("plotTime_s") = time(first:end);
buffer("plotValue") = values(first:end);
buffer("plotTimestampUTC") = timestamps(first:end);
end

function postRefreshIfDue(buffer, context)
elapsed_s = buffer("lastElapsed_s");
if buffer("refreshPending") || elapsed_s - buffer("lastRefresh_s") < 0.1
    return;
end
buffer("lastRefresh_s") = elapsed_s;
buffer("refreshPending") = true;
try
    context.postEvent("nidmm.recording.refresh", ...
        @ni_dmm_recorder.recording.refreshState);
catch cause
    clearRefreshPending(buffer);
    rethrow(cause);
end
end

function clearRefreshPending(buffer)
buffer("refreshPending") = false;
assert(~buffer("refreshPending"));
end
