function extensions = supportedExtensions()
%SUPPORTEDEXTENSIONS Return extensions supported by LabKit image file inputs.
%
% Usage:
%   extensions = labkit.image.supportedExtensions()
%
% Description:
%   Lists the filename extensions accepted by the generic LabKit image input
%   functions. Matching in labkit.image.isSupportedPath is case-insensitive.
%   This list describes source-image support; an individual app may offer a
%   smaller set of export formats.
%
% Inputs:
%   None.
%
% Outputs:
%   extensions - String column of lowercase extensions, including the
%                leading dot. The current values are .png, .jpg, .jpeg,
%                .tif, .tiff, and .bmp.
%
% Failure Behavior:
%   The function accepts no caller input and performs no file-system access.
%   It returns the fixed facade extension list without a recoverable failure
%   state.
%
% Example:
%   extensions = labkit.image.supportedExtensions();
%   acceptsTiff = any(extensions == ".tiff");
%
% See also labkit.image.isSupportedPath,
%   labkit.image.fileDialogFilter

    extensions = [".png"; ".jpg"; ".jpeg"; ".tif"; ".tiff"; ".bmp"];
end
