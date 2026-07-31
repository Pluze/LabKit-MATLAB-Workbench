function info = version()
%VERSION Return version information for the DTA API.
%
% Usage:
%   info = labkit.dta.version()
%
% Description:
%   Reports the API version and compatibility range used when an app declares
%   a dependency on labkit.dta. This is not the Gamry software version or a
%   version identifier read from a DTA file.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo. name is
%       "labkit.dta"; facade is "dta"; current is the current semantic
%       version; compatible lists supported requirement ranges; status
%       describes API maturity; and notes summarizes the module.
%
% Failure Behavior:
%   The function accepts no caller input. Invalid embedded facade metadata
%   raises labkit:contract:InvalidVersionInfo; released metadata is validated
%   by the contract test suite.
%
% Example:
%   info = labkit.dta.version();
%   fprintf("DTA API %s (%s)\n", info.current, info.status)
%
% See also labkit.contract.versionInfo,
%   labkit.contract.checkRequirements

    info = labkit.contract.versionInfo("dta", "3.1.0", ">=3 <4", ...
        "stable", "DTA parser, file item, pulse, and curve facade contract.");
end
