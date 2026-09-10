function devices = discover()
%DISCOVER Enumerate locally configured NI-DMM devices.
%
% Usage:
%   devices = labkit.nidmm.discover()
%
% Description:
%   Uses the end-user-installed NI System Configuration .NET API to find
%   local NI-DMM resources known to NI MAX. No device is opened or reset.
%
% Outputs:
%   devices - Column structure array with Resource, Model, and Bus fields.
%       Resource is the NI MAX alias accepted by labkit.nidmm.connect.
%
% Errors:
%   labkit:nidmm:UnsupportedPlatform - NI-DMM is unsupported here.
%   labkit:nidmm:DriverMissing - The NI-DMM .NET runtime is unavailable.
%   labkit:nidmm:DriverIncompatible - The NI-DMM API is incompatible.
%   labkit:nidmm:DiscoveryUnavailable - NI System Configuration is absent.
%   labkit:nidmm:DiscoveryFailed - Installed discovery software failed.
%
% Typical Call:
%   devices = labkit.nidmm.discover();
%   if ~isempty(devices)
%       connection = labkit.nidmm.connect(devices(1).Resource);
%   end
%
% See also labkit.nidmm.availability, labkit.nidmm.connect
status = niDmmAvailability();
if ~status.Available
    throwAvailability(status);
end
devices = niDmmDiscovery();
end

function throwAvailability(status)
switch status.Status
    case "unsupported_platform"
        id = "labkit:nidmm:UnsupportedPlatform";
    case "driver_incompatible"
        id = "labkit:nidmm:DriverIncompatible";
    otherwise
        id = "labkit:nidmm:DriverMissing";
end
throwAsCaller(MException(id, "%s", status.Message));
end
