function disconnect(connection)
%DISCONNECT Restore Auto Output and close a Mark-10 connection.
%
% Usage:
%   labkit.mark10.disconnect(connection)
%
% Description:
%   Restores the Auto Output token captured or selected for restoration,
%   closes any active Series 5 pass-through channel, drains pending bytes,
%   and closes the serial port. Cleanup is best-effort and idempotent.
%
% Inputs:
%   connection - Opaque scalar token returned by labkit.mark10.connect.
%
% Outputs:
%   None.
%
% Errors:
%   None for an already closed valid connection. Invalid tokens throw
%   labkit:mark10:InvalidConnection.
%
% Typical Call:
%   labkit.mark10.disconnect(connection);
%
% See also labkit.mark10.connect
    connection = requireConnection(connection);
    if mark10IsServiceConnection(connection)
        disconnectService(connection);
        return;
    end
    t = connection.Transport;
    if ~t.IsOpen()
        return;
    end
    try
        if strlength(connection.RestoreAutoOutput) > 0 && ...
                connection.RestoreAutoOutput ~= "AOUT0"
            t.Flush();
            t.Write(uint8('/'));
            t.Pause(0.015);
            t.Write([uint8(char(connection.RestoreAutoOutput)), uint8(13)]);
            t.ReadFor(0.08);
            t.Write(uint8('\'));
        end
    catch
    end
    try
        t.Close();
    catch
    end
end

function disconnectService(connection)
service = connection.Service;
if service("closed")
    return;
end
try
    mark10ServiceRequest(connection, "disconnect", struct());
catch
end
service("closed") = true;
service("consumer") = [];
future = service("future");
started = tic;
while ~isempty(future) && isvalid(future) && ...
        string(future.State) ~= "finished" && toc(started) < 1
    pause(0.005);
end
if ~isempty(future) && isvalid(future) && string(future.State) ~= "finished"
    cancel(future);
end
end

function connection = requireConnection(connection)
if ~isstruct(connection) || ~isscalar(connection) || ...
        ~isfield(connection, "Type") || ...
        string(connection.Type) ~= "labkit.mark10.connection" || ...
        ~isfield(connection, "Transport")
    error("labkit:mark10:InvalidConnection", ...
        "Expected a connection returned by labkit.mark10.connect.");
end
end
