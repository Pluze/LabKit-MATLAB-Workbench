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

    info = labkit.contract.versionInfo("ui", "6.0.4", ">=6 <7", ...
        "stable", "UI 6 Runtime V2 contract with validated stable identities, standard app launch, canonical project/session state, queued semantic events, deterministic presentation, managed interactions and resources, app-targeted and debounced recovery writes, runtime dialog/result services, portable source references, and read-only import of supported legacy projects and snapshots.");
end
