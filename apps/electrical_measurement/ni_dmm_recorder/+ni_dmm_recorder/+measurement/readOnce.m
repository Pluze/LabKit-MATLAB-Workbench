function applicationState = readOnce(applicationState, context)
%READONCE Apply current settings and update one live value without retaining it.
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
    [connection, sample] = labkit.nidmm.readSample(connection);
    box("connection") = connection;
    applicationState.session.connection.device = box("connection").Model;
    applicationState.session.configuration.applied = applied;
    applicationState.session.acquisition.value = sample.Value;
    applicationState.session.acquisition.unit = sample.Unit;
    applicationState.session.connection.status = "Connected; read completed.";
    applicationState.session.connection.lastFailure = sample.FailureStatus;
catch cause
    applicationState.session.connection.status = "Read failed.";
    applicationState.session.connection.lastFailure = string(cause.message);
    context.log("error", "ni_dmm_recorder.measurement.read.failed", ...
        "NI-DMM read failed", Category="acquisition", Exception=cause);
    context.alert(cause.message, "NI-DMM Read");
end
end
