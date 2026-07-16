function info = version()
%VERSION Return the LabKit UI facade contract version.
%
% App-facing contract:
%   info = labkit.ui.version()
%
% Inputs:
%   None.
%
% Outputs:
%   info - plain struct describing the current labkit.ui contract, the
%       compatible contract ranges implemented by this code, contract status,
%       and a short maintainer note.

    info = labkit.contract.versionInfo("ui", "7.3.0", ">=7 <8", ...
        "stable", "UI 7 Runtime V2 contract with one-definition App metadata, one project migration entry per App, minimal optional lifecycle capabilities, queued semantic events, deterministic presentation, managed interactions and resources, validated source and result collections, portable project references, runtime dialog/result services, and private serialization and busy-state mechanics.");
end
