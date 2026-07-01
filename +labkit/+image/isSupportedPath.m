function tf = isSupportedPath(pathValue)
%ISSUPPORTEDPATH Return true when a path has a supported image extension.
%
% App-facing contract:
%   tf = labkit.image.isSupportedPath(pathValue)
%
% Inputs:
%   pathValue - one path-like value.
%
% Outputs:
%   tf - scalar logical based only on the filename extension. The file is not
%       read and does not need to exist.

    [~, ~, ext] = fileparts(char(string(pathValue)));
    tf = any(strcmpi(string(ext), labkit.image.supportedExtensions()));
end
