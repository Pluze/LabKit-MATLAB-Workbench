function name = displayName(pathValue)
%DISPLAYNAME Return a short image-file display name.
%
% Usage:
%   name = labkit.image.displayName(pathValue)
%
% Description:
%   Removes the folder portion of one path and returns the final filename
%   with its extension. The function performs text processing only; the path
%   does not need to exist. If fileparts cannot derive a filename, the
%   trimmed input text is returned.
%
% Inputs:
%   pathValue - Character vector, string scalar, or another value convertible
%               to one string scalar.
%
% Outputs:
%   name - String scalar containing the filename and extension.
%
% Errors:
%   labkit:image:InvalidPath - pathValue converts to more than one string.
%
% Example:
%   name = labkit.image.displayName(fullfile("images", "frame01.tif"));

    pathText = string(pathValue);
    if ~isscalar(pathText)
        error('labkit:image:InvalidPath', ...
            'displayName expects one path value.');
    end

    [~, base, ext] = fileparts(char(pathText));
    name = string([base ext]);
    if strlength(name) == 0
        name = strtrim(pathText);
    end
end
