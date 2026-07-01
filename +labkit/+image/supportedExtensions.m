function extensions = supportedExtensions()
%SUPPORTEDEXTENSIONS Return extensions supported by LabKit image file inputs.
%
% App-facing contract:
%   extensions = labkit.image.supportedExtensions()
%
% Inputs:
%   None.
%
% Outputs:
%   extensions - string column of lowercase filename extensions including
%       leading dots. The list is intended for generic source-image inputs,
%       not app-specific export policy.

    extensions = [".png"; ".jpg"; ".jpeg"; ".tif"; ".tiff"; ".bmp"];
end
