function state = zeroTravel(state, context)
%ZEROTRAVEL Request hardware travel zero or adopt a software offset.
box = context.getResource("application", "mark10Connection");
connection = box("connection");
[connection, result] = labkit.mark10.zeroTravel(connection);
box("connection") = connection;
if result.Success
    acquisition = state.session.acquisition;
    previousOffset_mm = acquisition.travelZeroOffset_mm;
    acquisition.travelZeroOffset_mm = result.SoftwareOffset_mm;
    if result.HardwareApplied
        acquisition.travel_mm = result.After_mm;
        state.session.connection.status = "Hardware travel zero verified.";
    else
        offsetChange_mm = result.SoftwareOffset_mm - previousOffset_mm;
        if isfield(acquisition, "travel_mm") && ...
                isfinite(acquisition.travel_mm)
            acquisition.travel_mm = ...
                acquisition.travel_mm - offsetChange_mm;
        end
        if isfield(acquisition, "plotTravel_mm")
            acquisition.plotTravel_mm = ...
                acquisition.plotTravel_mm - offsetChange_mm;
        end
        state.session.connection.status = ...
            "Hardware zero unavailable in this mode; software zero active.";
    end
    state.session.acquisition = acquisition;
else
    state.session.connection.lastFailure = result.Message;
    context.alert(result.Message, "Zero Travel");
end
end
