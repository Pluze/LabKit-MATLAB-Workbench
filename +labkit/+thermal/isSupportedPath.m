function tf = isSupportedPath(path)
%ISSUPPORTEDPATH Return true for supported thermal source paths.
%
% App-facing contract:
%   tf = labkit.thermal.isSupportedPath(path)
%
% Inputs:
%   path - char, string, or scalar path-like value.
%
% Outputs:
%   tf - logical scalar. True when the extension is supported by the current
%       thermal facade reader set.

    [~, ~, ext] = fileparts(char(string(path)));
    tf = any(lower(string(ext)) == labkit.thermal.supportedExtensions());
end
