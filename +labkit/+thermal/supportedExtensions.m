function extensions = supportedExtensions()
%SUPPORTEDEXTENSIONS List the supported thermal filename extensions.
%
% Usage:
%   extensions = labkit.thermal.supportedExtensions()
%
% Description:
%   Returns the filename extensions recognized by the thermal file-selection
%   and reading functions. JPEG is a container format, so a listed extension
%   does not guarantee that a file contains FLIR radiometric data. Use
%   labkit.thermal.inspectFile to check a particular file.
%
% Outputs:
%   extensions - String row vector [".jpg", ".jpeg", ".rjpg"]. Extensions
%       are lowercase and include the leading period.
%
% Failure Behavior:
%   The function accepts no caller input and performs no file-system access.
%   It returns the fixed facade extension list without a recoverable failure
%   state.
%
% Example:
%   extensions = labkit.thermal.supportedExtensions();
%   pattern = "*" + strjoin(extensions, ";*");
%
% See also labkit.thermal.isSupportedPath,
%   labkit.thermal.fileDialogFilter,
%   labkit.thermal.inspectFile

    extensions = [".jpg", ".jpeg", ".rjpg"];
end
