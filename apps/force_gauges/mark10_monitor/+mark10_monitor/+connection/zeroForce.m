function state = zeroForce(state, context)
%ZEROFORCE Request gauge zero and report verified outcome.
box = context.getResource("mark10Connection");
connection = box("connection");
[connection, result] = labkit.mark10.zeroForce(connection);
mark10_monitor.connection.retain(box, connection);
if result.Success
    state.session.acquisition.force_N = result.After_N;
    state.session.connection.status = "Force zero verified.";
    state.session.connection.lastFailure = "";
else
    state.session.connection.lastFailure = result.Message;
    context.alert(result.Message, "Zero Force");
end
end
