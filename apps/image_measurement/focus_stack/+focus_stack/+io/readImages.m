% App-owned focus-stack image loading helper. Expected caller:
% labkit_FocusStack_app run callback. Input is a filePanel string column. Output
% is a cell column of image arrays. Reads image files and has no write side
% effects.
function images = readImages(paths)
%READIMAGES Read selected focus-stack images from disk.

    if isempty(paths)
        error('labkit_FocusStack_app:NoImagesSelected', ...
            'Select at least one image file.');
    end
    focus_stack.io.assertSupportedImagePaths(paths);

    images = cell(numel(paths), 1);
    for k = 1:numel(paths)
        if exist(char(paths(k)), 'file') ~= 2
            error('labkit_FocusStack_app:ImageFileNotFound', ...
                'Image file does not exist: %s', char(paths(k)));
        end
        images{k} = imread(char(paths(k)));
    end
end
