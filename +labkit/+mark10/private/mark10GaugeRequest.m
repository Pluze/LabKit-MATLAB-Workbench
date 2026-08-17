function [raw, outcome] = mark10GaugeRequest(connection, command)
% Execute one CR-terminated Series 5 GCL2 query through ESM303 pass-through.
connection = requireMark10Connection(connection);
t = connection.Transport;
t.Flush();
t.Write(uint8('/'));
t.Pause(0.015);
t.Flush();
t.Write([uint8(char(command)), uint8(13)]);
raw = t.ReadUntil(1, connection.Timeout);
t.Write(uint8('\'));
t.Pause(0.01);
t.Flush();
outcome = mark10ResponseOutcome(raw);
end
