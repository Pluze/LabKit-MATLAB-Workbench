function applicationState = refreshAvailability(applicationState, ~)
%REFRESHAVAILABILITY Inspect NI-DMM software without opening a device.
status = labkit.nidmm.availability();
applicationState.session.connection.available = status.Available;
applicationState.session.connection.status = status.Message;
if ~status.Available
    applicationState.session.connection.lastFailure = status.Status;
else
    applicationState.session.connection.lastFailure = "";
end
end
