function disconnect(connection)
%DISCONNECT Stop acquisition and close an NI-DMM connection.
%
% Usage:
%   labkit.nidmm.disconnect(connection)
%
% Inputs:
%   connection - Opaque token returned by labkit.nidmm.connect.
%
% Outputs:
%   None.
%
% Errors:
%   labkit:nidmm:InvalidConnection - The token is malformed.
%
% Typical Call:
%   labkit.nidmm.disconnect(connection);
%
% See also labkit.nidmm.connect, labkit.nidmm.stopSampling
if ~(isstruct(connection) && isscalar(connection) && ...
        isfield(connection, "Type") && ...
        string(connection.Type) == "labkit.nidmm.connection" && ...
        isfield(connection, "State") && isa(connection.State, "containers.Map"))
    error("labkit:nidmm:InvalidConnection", ...
        "Expected a connection returned by labkit.nidmm.connect.");
end
state = connection.State;
if isKey(state, "closed") && state("closed")
    return;
end
if isKey(state, "backend")
    backend = state("backend");
    backend.close();
end
state("closed") = true;
if ~state("closed")
    error("labkit:nidmm:DisconnectFailed", ...
        "NI-DMM connection state did not close.");
end
end
