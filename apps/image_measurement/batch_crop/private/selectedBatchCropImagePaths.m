% App-owned selected-file normalization helper. Expected caller:
% labkit_BatchImageCrop_app and batchImageCropWorkflow. Inputs are raw
% uigetfile values. Output is a sorted string column and has no file effects.
function paths = selectedBatchCropImagePaths(files, folder)
%SELECTEDBATCHCROPIMAGEPATHS Normalize manually selected image paths.
% Expected caller: labkit_BatchImageCrop_app and batchImageCropWorkflow. Inputs
% are raw uigetfile file/folder values. Output validates image extensions and
% sorts by display filename.

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
        error('labkit_BatchImageCrop_app:NoImagesSelected', ...
            'Select at least one image file.');
    end

    folder = string(folder);
    paths = strings(numel(names), 1);
    for k = 1:numel(names)
        paths(k) = string(fullfile(folder, names(k)));
    end
    paths = sortBatchCropPathsByName(paths);
    assertSupportedBatchCropImagePaths(paths);
end

function paths = sortBatchCropPathsByName(paths)
    names = strings(numel(paths), 1);
    for k = 1:numel(paths)
        names(k) = lower(string(displayNameFromPath(paths(k))));
    end
    [~, order] = sort(names);
    paths = paths(order);
end

function assertSupportedBatchCropImagePaths(paths)
    extensions = supportedBatchCropImageExtensions();
    for k = 1:numel(paths)
        [~, ~, ext] = fileparts(char(paths(k)));
        if ~any(strcmpi(ext, extensions))
            error('labkit_BatchImageCrop_app:UnsupportedImageFile', ...
                'Unsupported image file type: %s', char(paths(k)));
        end
    end
end

function extensions = supportedBatchCropImageExtensions()
    extensions = {'.png', '.jpg', '.jpeg', '.tif', '.tiff', '.bmp'};
end
