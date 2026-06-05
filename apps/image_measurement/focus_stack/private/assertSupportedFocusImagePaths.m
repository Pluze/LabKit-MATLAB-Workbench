% App-owned focus-stack extension validator. Expected caller: focus-stack app
% private loading helpers. Input is a path vector. Throws on unsupported image
% extensions and has no side effects.
function assertSupportedFocusImagePaths(paths)
%ASSERTSUPPORTEDFOCUSIMAGEPATHS Validate focus-stack image path extensions.
% Expected caller: focus-stack app private loading helpers. Input is a path
% vector. This helper throws on unsupported image extensions and has no side
% effects.

    for k = 1:numel(paths)
        if ~isSupportedFocusImagePath(paths(k))
            error('labkit_FocusStack_app:UnsupportedImageFile', ...
                'Unsupported image file type: %s', char(paths(k)));
        end
    end
end
