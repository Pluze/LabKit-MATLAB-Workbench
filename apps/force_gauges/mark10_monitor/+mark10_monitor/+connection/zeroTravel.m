function state = zeroTravel(state, context)
%ZEROTRAVEL Request and verify ESM303 device travel zero.
box = context.getResource("mark10Connection");
connection = box("connection");
[connection, result] = labkit.mark10.zeroTravel(connection);
mark10_monitor.connection.retain(box, connection);
if result.Success && result.HardwareApplied
    acquisition = state.session.acquisition;
    acquisition.travel_mm = result.After_mm;
    state.session.connection.status = "ESM303 device travel zero verified.";
    state.session.connection.lastFailure = "";
    state.session.acquisition = acquisition;
else
    message = result.Message;
    if strlength(message) == 0
        message = "ESM303 device travel zero was not applied.";
    end
    state.session.connection.lastFailure = message;
    context.alert(message, "Zero Travel");
end
end
