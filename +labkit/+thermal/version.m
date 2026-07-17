function info = version()
%VERSION Return version information for the thermal API.
%
% Usage:
%   info = labkit.thermal.version()
%
% Description:
%   Reports the version and compatibility range used when an app declares a
%   dependency on labkit.thermal. This is the API contract version, not the
%   MATLAB release or the version of a particular thermal camera format.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo. name is
%       "labkit.thermal"; facade is "thermal"; current is the current semantic
%       version; compatible lists supported requirement ranges; status
%       describes API maturity; and notes summarizes the module.
%
% Failure Behavior:
%   The function accepts no caller input. Invalid embedded facade metadata
%   raises labkit:contract:InvalidVersionInfo; released metadata is validated
%   by the contract test suite.
%
% Example:
%   info = labkit.thermal.version();
%   fprintf("Thermal API %s (%s)\n", info.current, info.status)
%
% See also labkit.contract.versionInfo,
%   labkit.contract.checkRequirements

    info = labkit.contract.versionInfo("thermal", "1.1.2", ">=1.0 <2", ...
        "experimental", "GUI-free thermal image facade for FLIR radiometric JPEG reads, raw sensor matrices, provenance-aware temperature conversion, and display rendering.");
end
