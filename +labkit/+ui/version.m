function info = version()
%VERSION Return the LabKit UI facade contract version.
%
% Usage:
%   info = labkit.ui.version()
%
% Description:
%   Reports the semantic version and compatibility range of the public
%   labkit.ui framework contract. Apps declare this range through
%   labkit.contract.requirements; it is independent of any App product or
%   saved-project schema version.
%
% Inputs:
%   None.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo with name,
%   facade, current, compatible, status, and notes fields.
%
% Failure Behavior:
%   The function accepts no caller input. Invalid embedded facade metadata
%   raises labkit:contract:InvalidVersionInfo; released metadata is validated
%   by the contract test suite.
%
% Example:
%   info = labkit.ui.version();
%   assert(startsWith(info.current, "7."))
%
% See also labkit.contract.versionInfo,
%   labkit.contract.requirements,
%   labkit.ui.runtime.define

    info = labkit.contract.versionInfo("ui", "7.5.1", ">=7 <8", ...
        "stable", "UI 7 Runtime V2 contract with one definition factory, one version-aware project migration entry per App, Runtime-owned canonical project and session validation, atomic source relinking and strict session reconstruction diagnostics, minimal optional lifecycle capabilities, canonical new-state construction, queued semantic events, deterministic presentation, managed interactions and resources, opaque portable source references with GUI-free record creation and path access, runtime dialog/result services, and private serialization and busy-state mechanics.");
end
