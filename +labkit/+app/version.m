function info = version()
%VERSION Return the LabKit App SDK facade contract version.
%
% Usage:
%   info = labkit.app.version()
%
% Description:
%   Reports the semantic version and compatibility range of the public
%   LabKit App SDK. The SDK owns App definitions, semantic layout,
%   transactions, runtime source-list paths, lifecycle, diagnostics, dialogs,
%   and native MATLAB presentation. Apps independently own result files and
%   any task-specific saved-state formats.
%
% Inputs:
%   None.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo with name,
%       current, compatible, status, and notes fields.
%
% Errors:
%   labkit:contract:InvalidVersionInfo - Embedded facade metadata is invalid.
%
% Example:
%   info = labkit.app.version();
%   assert(startsWith(info.current, "3."))
%
% See also labkit.contract.versionInfo,
%   labkit.contract.requirements,
%   labkit.app.Definition

    info = labkit.contract.versionInfo( ...
        "app", "3.1.1", ">=3 <4", "stable", ...
        "Small transactional App SDK with App-owned state and archives.");
end
