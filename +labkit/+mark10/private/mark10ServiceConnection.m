function connection = mark10ServiceConnection(service)
% Rebuild one opaque client proxy from the worker's latest metadata.
metadata = service("metadata");
connection = metadata;
connection.Type = "labkit.mark10.connection";
connection.Service = service;
connection.Transport = struct();
end
