function assertSupportedPaths(paths)
%ASSERTSUPPORTEDPATHS Throw when any path has an unsupported image extension.
%
% Usage:
%   labkit.image.assertSupportedPaths(paths)
%
% Description:
%   Validates a collection of source-image paths by filename extension. The
%   function accepts the same path forms as labkit.image.normalizePaths and
%   stops at the first unsupported extension. It does not test whether files
%   exist or contain valid image data. Empty input succeeds.
%
% Inputs:
%   paths - Character vector, string array, cell array, or empty value
%           accepted by labkit.image.normalizePaths.
%
% Outputs:
%   None.
%
% Errors:
%   labkit:image:UnsupportedImageFile - A normalized path has an extension
%                                       outside supportedExtensions.
%   labkit:image:InvalidPaths - paths has an unsupported container type.
%
% Example:
%   labkit.image.assertSupportedPaths(["frame01.png"; "frame02.TIF"]);

    paths = labkit.image.normalizePaths(paths);
    for k = 1:numel(paths)
        if ~labkit.image.isSupportedPath(paths(k))
            error('labkit:image:UnsupportedImageFile', ...
                'Unsupported image file type: %s', char(paths(k)));
        end
    end
end
