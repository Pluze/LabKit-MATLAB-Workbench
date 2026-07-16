function info = version()
%VERSION Return version information for the RHS API.
%
% Usage:
%   info = labkit.rhs.version()
%
% Description:
%   Reports the API version and compatibility range used when an app declares
%   a dependency on labkit.rhs. This is not the file-format version stored in
%   an Intan recording.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo. name is
%       "rhs"; version is the current semantic version; compatibility is the
%       supported requirement range; stability describes API maturity; and
%       notes summarizes the module.
%
% Example:
%   info = labkit.rhs.version();
%   fprintf("RHS API %s (%s)\n", info.version, info.stability)

    info = labkit.contract.versionInfo("rhs", "1.0.1", ">=1.0 <2", ...
        "stable", "RHS discovery, metadata, indexing, and waveform-window facade contract.");
end
