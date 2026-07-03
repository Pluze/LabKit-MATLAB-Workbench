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
    records = labkit.image.readFiles(paths, struct("Normalize", false, ...
        "AllowEmpty", false));
    images = cell(numel(records), 1);
    for k = 1:numel(records)
        images{k} = records(k).image;
    end
end
