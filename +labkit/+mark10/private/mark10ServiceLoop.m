function mark10ServiceLoop(port, timeout, events)
% Own the physical Mark-10 connection and paced reads off the client.
connection = mark10ConnectLocal(port, Timeout=timeout);
lifetime = containers.Map("KeyType", "char", "ValueType", "any");
lifetime("connection") = connection;
cleanup = onCleanup(@() labkit.mark10.disconnect(lifetime("connection")));
commands = parallel.pool.PollableDataQueue;
send(events, event("ready", uint64(0), {commands}, connection));
monitoring = false;
period = 0.02;
sessionClock = tic;
nextDue_s = 0;
lastSend_s = 0;
batch = cell(1, 10);
batchCount = 0;
running = true;
while running
    if monitoring
        command = poll(commands, 0);
    else
        command = poll(commands, 0.05);
    end
    if ~isempty(command)
        [connection, monitoring, period, sessionClock, nextDue_s, ...
            batch, batchCount, running] = processCommand( ...
            connection, monitoring, period, sessionClock, nextDue_s, ...
            batch, batchCount, command, events);
        lifetime("connection") = connection;
        lastSend_s = toc(sessionClock);
        continue;
    end
    if ~monitoring
        continue;
    end
    elapsed_s = toc(sessionClock);
    if elapsed_s < nextDue_s
        pause(min(0.001, nextDue_s - elapsed_s));
        continue;
    end
    [connection, sample] = labkit.mark10.readSample(connection);
    lifetime("connection") = connection;
    sample.HostTime_s = toc(sessionClock);
    batchCount = batchCount + 1;
    batch{batchCount} = sample;
    nextDue_s = nextDue_s + period;
    if batchCount >= 10 || sample.HostTime_s - lastSend_s >= 0.1
        send(events, event("samples", uint64(0), ...
            batch(1:batchCount), connection));
        batch = cell(1, 10);
        batchCount = 0;
        lastSend_s = sample.HostTime_s;
    end
end
clear cleanup
end

function [connection, monitoring, period, sessionClock, nextDue_s, ...
        batch, batchCount, running] = processCommand( ...
        connection, monitoring, period, sessionClock, nextDue_s, ...
        batch, batchCount, command, events)
running = true;
action = string(command.Action);
requestId = command.RequestId;
payload = command.Payload;
try
    switch action
        case "start"
            connection = mark10EnsureForceConvention(connection);
            period = double(payload.Period);
            monitoring = true;
            sessionClock = tic;
            nextDue_s = 0;
            batch = cell(1, 10);
            batchCount = 0;
            result = {};
        case "stop"
            flushBatch(events, batch, batchCount, connection);
            batch = cell(1, 10);
            batchCount = 0;
            monitoring = false;
            result = {};
        case "setPeriod"
            period = double(payload.Period);
            nextDue_s = toc(sessionClock) + period;
            result = {};
        case "readSample"
            [connection, sample] = labkit.mark10.readSample(connection);
            result = {sample};
        case "readSettings"
            [connection, settings] = labkit.mark10.readSettings(connection);
            result = {settings};
        case "writeSetting"
            [connection, settings, writeResult] = ...
                labkit.mark10.writeSetting(connection, payload.Name, payload.Value);
            result = {settings, writeResult};
        case "zeroForce"
            [connection, zeroResult] = labkit.mark10.zeroForce(connection);
            result = {zeroResult};
        case "zeroTravel"
            [connection, zeroResult] = labkit.mark10.zeroTravel(connection);
            result = {zeroResult};
        case "disconnect"
            flushBatch(events, batch, batchCount, connection);
            batch = cell(1, 10);
            batchCount = 0;
            monitoring = false;
            result = {};
            running = false;
        otherwise
            error("labkit:mark10:InvalidValue", ...
                "Unknown Mark-10 service action: %s.", action);
    end
    send(events, event("response", requestId, result, connection));
catch cause
    failure = struct("Identifier", string(cause.identifier), ...
        "Message", string(cause.message));
    send(events, event("failure", requestId, {failure}, connection));
end
end

function flushBatch(events, batch, batchCount, connection)
if batchCount > 0
    send(events, event("samples", uint64(0), ...
        batch(1:batchCount), connection));
end
end

function value = event(type, requestId, payload, connection)
value = struct("Type", string(type), "RequestId", uint64(requestId), ...
    "Payload", {payload}, "Metadata", mark10ServiceMetadata(connection));
end
