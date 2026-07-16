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
%       "thermal"; version is the current semantic version; compatibility is
%       the supported requirement range; stability describes API maturity;
%       and notes summarizes the module.
%
% Example:
%   info = labkit.thermal.version();
%   fprintf("Thermal API %s (%s)\n", info.version, info.stability)

    info = labkit.contract.versionInfo("thermal", "1.1.0", ">=1.0 <2", ...
        "experimental", "GUI-free thermal image facade for FLIR radiometric JPEG reads, raw sensor matrices, provenance-aware temperature conversion, and display rendering.");
end
