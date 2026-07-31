function info = version()
%VERSION Return the LabKit biosignal facade contract version.
%
% Usage:
%   info = labkit.biosignal.version()
%
% Description:
%   Reports the semantic version and compatibility range of the public
%   labkit.biosignal API. Use this information when an app or saved project
%   needs to check whether the installed biosignal facade satisfies a known
%   contract range.
%
% Inputs:
%   None.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo. It
%          identifies the biosignal component, current version, compatible
%          contract range, stability status, and a short description.
%
% Failure Behavior:
%   The function accepts no caller input. Invalid embedded facade metadata
%   raises labkit:contract:InvalidVersionInfo; released metadata is validated
%   by the contract test suite.
%
% Example:
%   info = labkit.biosignal.version();
%   currentVersion = info.current;
%
% See also labkit.contract.versionInfo,
%   labkit.contract.checkRequirements

    info = labkit.contract.versionInfo("biosignal", "1.0.4", ">=1.0 <2", ...
        "stable", "Biosignal recording, filtering, event, segmentation, and ECG facade contract.");
end
