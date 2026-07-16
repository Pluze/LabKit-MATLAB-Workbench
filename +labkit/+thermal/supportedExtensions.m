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
% Example:
%   extensions = labkit.thermal.supportedExtensions();
%   pattern = "*" + strjoin(extensions, ";*");

    extensions = [".jpg", ".jpeg", ".rjpg"];
end
