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
% Example:
%   info = labkit.dta.version();
%   fprintf("DTA API %s (%s)\n", info.current, info.status)

    info = labkit.contract.versionInfo("dta", "2.0.1", ">=2.0 <3", ...
        "stable", "DTA parser, file item, pulse, and curve facade contract.");
end
