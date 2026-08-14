function state = zeroTravel(state, context)
%ZEROTRAVEL Request hardware travel zero or adopt a software offset.
box = context.getResource("application", "mark10Connection");
connection = box("connection");
[connection, result] = labkit.mark10.zeroTravel(connection);
box("connection") = connection;
if result.Success
    state.session.acquisition.travelZeroOffset_mm = ...
        result.SoftwareOffset_mm;
    if result.HardwareApplied
        state.session.connection.status = "Hardware travel zero verified.";
    else
        state.session.connection.status = ...
            "Hardware zero unavailable in this mode; software zero active.";
    end
else
    state.session.connection.lastFailure = result.Message;
    context.alert(result.Message, "Zero Travel");
end
end
