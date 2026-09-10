function applicationState = start(applicationState, context)
%START Configure the device and begin one in-memory recording.
if ~applicationState.session.connection.connected || ...
        applicationState.session.acquisition.recording
    return;
end
try
    request = ni_dmm_recorder.measurement.configuration( ...
        applicationState.session.configuration);
    box = context.getResource("nidmmConnection");
    connection = box("connection");
    [connection, applied] = labkit.nidmm.configure(connection, ...
        Mode=request.Mode, Range=request.Range, Digits=request.Digits);
    box("connection") = connection;
    buffer = context.getResource("nidmmBuffer");
    buffer = resetBuffer(buffer, applied);
    sampler = labkit.nidmm.startSampling(connection, 1 / request.Rate_Hz, ...
        @(updated, samples) ni_dmm_recorder.recording.receiveSamples( ...
            box, buffer, context, updated, samples));
    buffer("startedAtUTC") = sampler.StartedAtUTC;
    if isnat(buffer("startedAtUTC"))
        error("ni_dmm_recorder:InvalidStartTime", ...
            "NI-DMM acquisition did not provide a UTC start time.");
    end
    context.setResource("nidmmSampler", sampler, ...
        @(value) cleanupSampler(value, box));
    applicationState.session.configuration.applied = applied;
    applicationState.session.acquisition.recording = true;
    applicationState.session.cache.plotRevision = ...
        applicationState.session.cache.plotRevision + 1;
    applicationState.session.connection.status = "Connected and recording.";
    applicationState.session.export.status = ...
        "Recording in progress; samples retained in memory.";
catch cause
    applicationState.session.connection.status = "Recording could not start.";
    applicationState.session.connection.lastFailure = string(cause.message);
    context.log("error", "ni_dmm_recorder.recording.start.failed", ...
        "NI-DMM recording failed to start", ...
        Category="acquisition", Exception=cause);
    context.alert(cause.message, "NI-DMM Recording");
end
end

function buffer = resetBuffer(buffer, configuration)
replacement = ni_dmm_recorder.recording.createBuffer();
for key = string(keys(replacement))
    buffer(char(key)) = replacement(char(key));
end
buffer("configuration") = configuration;
end

function box = cleanupSampler(sampler, box)
connection = labkit.nidmm.stopSampling(sampler);
box("connection") = connection;
end
