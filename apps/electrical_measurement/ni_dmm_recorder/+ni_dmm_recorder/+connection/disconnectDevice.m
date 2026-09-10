function applicationState = disconnectDevice(applicationState, context)
%DISCONNECTDEVICE Stop recording and release the NI-DMM resource.
if applicationState.session.acquisition.recording
    applicationState = ni_dmm_recorder.recording.stop(applicationState, context);
end
if applicationState.session.connection.connected
    context.removeResource("nidmmConnection");
end
applicationState.session.connection.connected = false;
applicationState.session.connection.device = "Not connected";
applicationState.session.connection.status = "Disconnected.";
end
