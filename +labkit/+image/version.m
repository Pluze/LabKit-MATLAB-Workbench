function info = version()
%VERSION Return the LabKit image facade contract version.
%
% Usage:
%   info = labkit.image.version()
%
% Description:
%   Reports the semantic version and compatibility range of the public
%   labkit.image API. Apps can use this structure to check whether the
%   installed image facade satisfies a saved or declared requirement.
%
% Inputs:
%   None.
%
% Outputs:
%   info - Scalar structure returned by labkit.contract.versionInfo with
%          name, facade, current, compatible, status, and notes fields.
%
% Example:
%   info = labkit.image.version();
%   currentVersion = info.current;

    info = labkit.contract.versionInfo("image", "2.0.1", ">=2.0 <3", ...
        "stable", "GUI-free image file input, basic processing, and preview-budget helpers for responsive image apps.");
end
