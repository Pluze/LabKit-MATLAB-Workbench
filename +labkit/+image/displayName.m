function name = displayName(pathValue)
%DISPLAYNAME Return a short image-file display name.
%
% App-facing contract:
%   name = labkit.image.displayName(pathValue)
%
% Inputs:
%   pathValue - one char, string, or scalar path-like value.
%
% Outputs:
%   name - string scalar containing filename plus extension. If no filename
%       can be derived, the trimmed input text is returned.

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
