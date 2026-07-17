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

    info = labkit.contract.versionInfo("ui", "7.4.5", ">=7 <8", ...
        "stable", "UI 7 Runtime V2 contract with one-definition App metadata, one project migration entry per App, Runtime-owned canonical project and session validation, minimal optional lifecycle capabilities, canonical new-state construction, queued semantic events, deterministic presentation, managed interactions and resources, opaque portable source references with GUI-free record creation and path access, runtime dialog/result services, and private serialization and busy-state mechanics.");
end
