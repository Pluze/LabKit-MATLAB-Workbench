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
%       "labkit.rhs"; facade is "rhs"; current is the current semantic
%       version; compatible lists supported requirement ranges; status
%       describes API maturity; and notes summarizes the module.
%
% Example:
%   info = labkit.rhs.version();
%   fprintf("RHS API %s (%s)\n", info.current, info.status)

    info = labkit.contract.versionInfo("rhs", "1.0.1", ">=1.0 <2", ...
        "stable", "RHS discovery, metadata, indexing, and waveform-window facade contract.");
end
