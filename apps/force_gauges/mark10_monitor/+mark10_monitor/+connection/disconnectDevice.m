function state = disconnectDevice(state, context)
%DISCONNECTDEVICE Stop monitoring and close the Mark-10 connection.
if ~state.session.connection.connected
    return;
end
state.session.connection.connected = false;
state.session.acquisition.recording = false;
buffer = context.getResource("application", "mark10Buffer");
buffer("recording") = false;
context.removeResource("application", "mark10Timer");
context.removeResource("application", "mark10Connection");
state.session.connection.status = "Disconnected; recorded data retained.";
end
