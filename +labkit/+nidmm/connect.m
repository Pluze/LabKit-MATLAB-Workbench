function connection = connect(resource)
%CONNECT Open one NI-DMM resource through the user-installed driver.
%
% Usage:
%   connection = labkit.nidmm.connect(resource)
%
% Inputs:
%   resource - Nonempty NI MAX resource name, such as "Dev1".
%
% Outputs:
%   connection - Opaque scalar token accepted by other labkit.nidmm calls.
%       Model and DriverVersion contain non-sensitive diagnostics.
%
% Errors:
%   labkit:nidmm:UnsupportedPlatform - The platform cannot host USB NI-DMM.
%   labkit:nidmm:DriverMissing - The NI-DMM .NET runtime is unavailable.
%   labkit:nidmm:DriverIncompatible - The installed runtime lacks the API.
%   labkit:nidmm:ConnectionFailed - The resource is absent, busy, or rejected.
%
% Typical Call:
%   connection = labkit.nidmm.connect("Dev1");
%   cleanup = onCleanup(@() labkit.nidmm.disconnect(connection));
%
% See also labkit.nidmm.availability, labkit.nidmm.disconnect
resource = scalarText(resource, "resource");
backend = openNiDmmBackend(resource);
state = containers.Map("KeyType", "char", "ValueType", "any");
state("backend") = backend;
state("configured") = false;
state("configuration") = struct();
state("closed") = false;
connection = struct("Type", "labkit.nidmm.connection", ...
    "Resource", resource, "Model", backend.Model, ...
    "DriverVersion", backend.DriverVersion, "State", state);
end

function value = scalarText(value, label)
if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
        strlength(strip(string(value))) == 0
    error("labkit:nidmm:InvalidValue", ...
        "NI-DMM %s must be nonempty scalar text.", label);
end
value = strip(string(value));
end
