% App-owned focus-stack selected-file normalization helper. Expected caller:
% labkit_FocusStack_app and focus_stack package tests. Inputs are raw uigetfile values.
% Output is a sorted string column of image paths. Validates extensions only and
% has no file side effects.
function paths = selectedImagePaths(files, folder)
%SELECTEDIMAGEPATHS Normalize manually selected focus-stack image paths.
% Expected caller: labkit_FocusStack_app and focus_stack package tests. Inputs are the
% raw uigetfile files value and folder value. Output is a sorted string column.
% This helper validates extensions only and has no file side effects.

    if isequal(files, 0) || isequal(folder, 0)
        paths = strings(0, 1);
        return;
    end

    if iscell(files)
        names = string(files(:));
    else
        names = string(files);
        names = names(:);
    end
    names = names(strlength(names) > 0);
    if isempty(names)
        error('labkit_FocusStack_app:NoImagesSelected', ...
            'Select at least one image file.');
    end

    folder = string(folder);
    paths = strings(numel(names), 1);
    for k = 1:numel(names)
        paths(k) = string(fullfile(folder, names(k)));
    end
    paths = focus_stack.io.sortPathsByName(paths);
    focus_stack.io.assertSupportedImagePaths(paths);
end
