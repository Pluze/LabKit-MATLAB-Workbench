function [raw, outcome, elapsed] = mark10StandRequest( ...
        connection, command, lineCount, flushFirst)
% Execute one fixed-format ESM303 request and retain exact response bytes.
connection = requireMark10Connection(connection);
if flushFirst
    connection.Transport.Flush();
end
started = tic;
connection.Transport.Write(uint8(char(command)));
raw = connection.Transport.ReadUntil(lineCount, connection.Timeout);
elapsed = toc(started);
outcome = mark10ResponseOutcome(raw);
end
