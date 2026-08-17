function [raw, outcome] = mark10GaugeCommand(connection, command)
% Execute one Series 5 setter without requiring an acknowledgement.
connection = requireMark10Connection(connection);
t = connection.Transport;
t.Flush();
t.Write(uint8('/'));
t.Pause(0.015);
t.Flush();
t.Write([uint8(char(command)), uint8(13)]);
raw = t.ReadFor(min(0.08, connection.Timeout));
t.Write(uint8('\'));
t.Pause(0.01);
t.Flush();
outcome = mark10ResponseOutcome(raw);
end
