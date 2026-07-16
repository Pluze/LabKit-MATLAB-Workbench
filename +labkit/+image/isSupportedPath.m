function tf = isSupportedPath(pathValue)
%ISSUPPORTEDPATH Return true when a path has a supported image extension.
%
% Usage:
%   tf = labkit.image.isSupportedPath(pathValue)
%
% Description:
%   Compares the final filename extension with
%   labkit.image.supportedExtensions. The comparison is case-insensitive and
%   does not open the file, inspect its contents, or require it to exist.
%   A path with no extension returns false.
%
% Inputs:
%   pathValue - One value convertible to text and accepted by fileparts.
%
% Outputs:
%   tf - Logical scalar indicating whether the extension is supported.
%
% Example:
%   tf = labkit.image.isSupportedPath("experiment.TIFF");

    [~, ~, ext] = fileparts(char(string(pathValue)));
    tf = any(strcmpi(string(ext), labkit.image.supportedExtensions()));
end
