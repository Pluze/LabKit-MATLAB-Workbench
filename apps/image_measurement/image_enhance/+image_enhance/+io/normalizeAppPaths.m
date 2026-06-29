% Expected caller: labkit_ImageEnhance_app runner. Input is char, string, or
% cell image paths from UI/filePanel events. Output is a nonempty string
% column suitable for app-owned readers.
function paths = normalizeAppPaths(paths)
    if isempty(paths)
        paths = strings(0, 1);
    elseif ischar(paths)
        paths = string({paths});
    elseif isstring(paths)
        paths = paths(:);
    elseif iscell(paths)
        paths = string(paths(:));
    else
        error('labkit_ImageEnhance_app:InvalidImagePaths', ...
            'Image paths must be char, string, or a cell array.');
    end
    paths = paths(strlength(paths) > 0);
end
