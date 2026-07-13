function info = version()
%VERSION Return the LabKit image facade contract version.
%
% App-facing contract:
%   info = labkit.image.version()
%
% Inputs:
%   None.
%
% Outputs:
%   info - plain struct describing the current labkit.image contract, the
%       compatible contract ranges implemented by this code, contract status,
%       and a short maintainer note.

    info = labkit.contract.versionInfo("image", "2.0.0", ">=2.0 <3", ...
        "stable", "GUI-free image file input, basic processing, and preview-budget helpers for responsive image apps.");
end
