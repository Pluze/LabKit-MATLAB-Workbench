function info = version()
%VERSION Return the LabKit NI-DMM facade contract version.
%
% Usage:
%   info = labkit.nidmm.version()
%
% Description:
%   Reports the semantic version and compatibility range of the GUI-free
%   NI-DMM facade. This function does not load the vendor driver.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo.
%
% Errors:
%   labkit:contract:InvalidVersionInfo - Embedded metadata is invalid.
%
% Example:
%   info = labkit.nidmm.version();
%   assert(info.current == "1.0.0")
%
% See also labkit.nidmm.availability, labkit.nidmm.connect
info = labkit.contract.versionInfo( ...
    "nidmm", "1.0.0", ">=1 <2", "stable", ...
    "NI-DMM voltage, current, resistance, diode, and buffered acquisition facade.");
end
