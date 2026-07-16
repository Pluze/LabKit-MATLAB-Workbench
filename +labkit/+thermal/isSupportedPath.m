function tf = isSupportedPath(path)
%ISSUPPORTEDPATH Test whether a path has a supported thermal extension.
%
% Usage:
%   tf = labkit.thermal.isSupportedPath(path)
%
% Description:
%   Compares the filename extension with the extensions returned by
%   labkit.thermal.supportedExtensions. The comparison is case-insensitive.
%   This function does not access the file system and does not check whether a
%   JPEG contains radiometric data. Use labkit.thermal.inspectFile when the
%   file contents must be verified.
%
% Inputs:
%   path - Character vector or string scalar containing a filename or path.
%
% Outputs:
%   tf - Logical scalar. The value is true for .jpg, .jpeg, and .rjpg names
%       and false for all other extensions.
%
% Example:
%   labkit.thermal.isSupportedPath("capture.RJPG")  % returns true
%   labkit.thermal.isSupportedPath("capture.png")   % returns false

    [~, ~, ext] = fileparts(char(string(path)));
    tf = any(lower(string(ext)) == labkit.thermal.supportedExtensions());
end
