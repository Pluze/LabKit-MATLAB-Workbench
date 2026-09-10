function applicationState = stop(applicationState, context)
%STOP End recording while keeping the NI-DMM resource connected.
if ~applicationState.session.acquisition.recording
    return;
end
context.removeResource("nidmmSampler");
applicationState = ni_dmm_recorder.recording.refreshState( ...
    applicationState, context);
applicationState.session.acquisition.recording = false;
applicationState.session.connection.status = ...
    "Connected; recording stopped.";
applicationState.session.export.status = compose( ...
    "Recording stopped: %d valid samples retained.", ...
    applicationState.session.acquisition.validCount);
end
