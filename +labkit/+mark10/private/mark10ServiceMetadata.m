function metadata = mark10ServiceMetadata(connection)
% Return the serializable public snapshot retained by the client proxy.
names = ["Port", "Timeout", "Identity", "Capabilities", "Settings", ...
    "RestoreAutoOutput", "AcquisitionMode", "SampleCount", "LastFailure"];
metadata = struct();
for name = names
    metadata.(name) = connection.(name);
end
end
