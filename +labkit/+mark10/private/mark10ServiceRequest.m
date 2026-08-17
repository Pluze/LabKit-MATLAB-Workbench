function [connection, payload] = mark10ServiceRequest(connection, action, payload)
% Send one ordered high-level command to the background driver actor.
connection = requireMark10Connection(connection);
if ~mark10IsServiceConnection(connection)
    error("labkit:mark10:InvalidConnection", ...
        "Mark-10 background service is unavailable.");
end
service = connection.Service;
requestId = service("nextRequestId") + uint64(1);
service("nextRequestId") = requestId;
command = struct("Action", string(action), "RequestId", requestId, ...
    "Payload", payload);
send(service("commands"), command);
value = mark10ServiceAwait(service, "request-" + string(requestId), ...
    max(2, 4 * connection.Timeout));
service("metadata") = value.Metadata;
connection = mark10ServiceConnection(service);
payload = value.Payload;
end
