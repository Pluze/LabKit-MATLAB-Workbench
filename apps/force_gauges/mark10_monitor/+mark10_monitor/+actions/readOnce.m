function state = readOnce(state, context)
%READONCE Refresh the live readout without starting or retaining monitoring.
if state.session.acquisition.monitoring
    return;
end
box = context.getResource("application", "mark10Connection");
connection = box("connection");
[connection, sample] = labkit.mark10.readSample(connection);
box("connection") = connection;
if ~sample.Valid
    message = "No valid synchronized force/travel reading was received.";
    state.session.connection.lastFailure = message;
    context.alert(message, "Read Once");
    return;
end
state.session.acquisition.force_N = sample.Force_N;
state.session.acquisition.travel_mm = sample.Travel_mm - ...
    state.session.acquisition.travelZeroOffset_mm;
state.session.connection.acquisitionMode = sample.AcquisitionMode;
state.session.connection.lastFailure = "";
state.session.connection.status = "Manual device reading updated.";
end
