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

    info = labkit.contract.versionInfo("ui", "7.0.0", ">=7 <8", ...
        "stable", "UI 7 Runtime V2 contract with validated stable identities, standard app launch, canonical project/session state, queued semantic events, deterministic presentation, managed interactions and resources, destination-rebased project and recovery source references, runtime dialog/result services, and serialization and busy-state mechanics kept private behind injected services and semantic actions.");
end
