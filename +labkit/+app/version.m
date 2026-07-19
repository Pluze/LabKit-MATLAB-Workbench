function info = version()
%VERSION Return the LabKit App SDK facade contract version.
%
% Usage:
%   info = labkit.app.version()
%
% Description:
%   Reports the semantic version and compatibility range of the public
%   LabKit App SDK. The SDK owns App definitions, semantic layout,
%   transactions, projects, portable sources, resources, results, dialogs,
%   and native MATLAB presentation. It is independent of App product and
%   saved-project schema versions.
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
%   assert(startsWith(info.current, "1."))
%
% See also labkit.contract.versionInfo,
%   labkit.contract.requirements,
%   labkit.app.Definition

    info = labkit.contract.versionInfo( ...
        "app", "1.0.0", ">=1 <2", "experimental", ...
        "Explicit LabKit App SDK contract under active tracked-App migration.");
end
