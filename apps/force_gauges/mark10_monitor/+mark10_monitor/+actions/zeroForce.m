function state = zeroForce(state, context)
%ZEROFORCE Request gauge zero and report verified outcome.
box = context.getResource("application", "mark10Connection");
connection = box("connection");
[connection, result] = labkit.mark10.zeroForce(connection);
box("connection") = connection;
if result.Success
    state.session.connection.status = "Force zero verified.";
else
    state.session.connection.lastFailure = result.Message;
    context.alert(result.Message, "Zero Force");
end
end
