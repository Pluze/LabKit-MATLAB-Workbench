function state = refresh(state, context)
%REFRESH Read Series 5 settings without changing them.
box = context.getResource("application", "mark10Connection");
connection = box("connection");
[connection, settings] = labkit.mark10.readSettings(connection);
mark10_monitor.connection.retain(box, connection);
state = mark10_monitor.settings.copyReadback(state, settings);
end
