function info = version()
%VERSION Return the LabKit Mark-10 driver facade contract version.
%
% Usage:
%   info = labkit.mark10.version()
%
% Description:
%   Reports the semantic version and compatibility range of the GUI-free
%   Mark-10 ESM303 and Series 5 communication facade.
%
% Inputs:
%   None.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo.
%
% Errors:
%   labkit:contract:InvalidVersionInfo - Embedded metadata is invalid.
%
% Example:
%   info = labkit.mark10.version();
%   assert(info.current == "1.0.1")
%
% See also labkit.mark10.connect, labkit.mark10.readSample
    info = labkit.contract.versionInfo( ...
        "mark10", "1.0.1", ">=1 <2", "stable", ...
        "Mark-10 ESM303 and Series 5 monitor and settings driver.");
end
