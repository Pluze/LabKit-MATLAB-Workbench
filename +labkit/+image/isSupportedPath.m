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
% Failure Behavior:
%   Missing or unknown extensions return false without accessing the file
%   system. pathValue must be convertible to scalar text; unsupported MATLAB
%   values or shapes may raise the originating string or fileparts error.
%
% Example:
%   tf = labkit.image.isSupportedPath("experiment.TIFF");
%
% See also labkit.image.supportedExtensions,
%   labkit.image.assertSupportedPaths,
%   labkit.image.normalizePaths

    [~, ~, ext] = fileparts(char(string(pathValue)));
    tf = any(strcmpi(string(ext), labkit.image.supportedExtensions()));
end
