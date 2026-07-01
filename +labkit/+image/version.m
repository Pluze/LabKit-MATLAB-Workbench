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

    info = labkit.contract.versionInfo("image", "1.0.0", ">=1.0 <2", ...
        "stable", "GUI-free image file input facade for extension filters, path normalization, display names, and imread-backed source records.");
end
