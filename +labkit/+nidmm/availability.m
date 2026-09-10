function status = availability()
%AVAILABILITY Inspect the user-installed NI-DMM runtime without opening hardware.
%
% Usage:
%   status = labkit.nidmm.availability()
%
% Description:
%   Checks platform compatibility and loads the fixed NI-DMM .NET assembly
%   installed by the end user. It does not open, reset, or discover devices.
%
% Outputs:
%   status - Scalar structure with Available, Status, Message,
%       DriverVersion, and RequiredComponent fields.
%
% Errors:
%   None. Missing or incompatible software is returned as status data.
%
% Typical Call:
%   status = labkit.nidmm.availability();
%
% See also labkit.nidmm.connect, labkit.nidmm.version
status = niDmmAvailability();
end
