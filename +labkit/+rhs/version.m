function info = version()
%VERSION Return the LabKit RHS facade contract version.
%
% App-facing contract:
%   info = labkit.rhs.version()
%
% Inputs:
%   None.
%
% Outputs:
%   info - plain struct describing the current labkit.rhs contract, the
%       compatible contract ranges implemented by this code, contract status,
%       and a short maintainer note.

    info = labkit.contract.versionInfo("rhs", "1.0.0", ">=1.0 <2", ...
        "stable", "RHS discovery, metadata, indexing, and waveform-window facade contract.");
end
