function assertSupportedPaths(paths)
%ASSERTSUPPORTEDPATHS Throw when any path has an unsupported image extension.
%
% App-facing contract:
%   labkit.image.assertSupportedPaths(paths)
%
% Inputs:
%   paths - char, string, cell array, or empty value accepted by
%       labkit.image.normalizePaths.
%
% Outputs:
%   None. Throws labkit:image:UnsupportedImageFile on the first unsupported
%       extension.

    paths = labkit.image.normalizePaths(paths);
    for k = 1:numel(paths)
        if ~labkit.image.isSupportedPath(paths(k))
            error('labkit:image:UnsupportedImageFile', ...
                'Unsupported image file type: %s', char(paths(k)));
        end
    end
end
