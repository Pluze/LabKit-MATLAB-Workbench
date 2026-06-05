% App-owned focus-stack folder discovery helper. Expected caller:
% labkit_FocusStack_app and focus_stack package tests. Input is a folder path. Output
% is a sorted string column of supported image paths. Reads directory metadata
% only and has no write side effects.
function paths = findImages(folder)
%FINDIMAGES Find supported focus-stack image files in a folder.
% Expected caller: labkit_FocusStack_app and focus_stack package tests. Input is a
% folder path. Output is a sorted string column of supported image file paths.
% This helper reads directory metadata only and has no write side effects.

    if strlength(string(folder)) == 0 || exist(folder, 'dir') ~= 7
        error('labkit_FocusStack_app:FolderNotFound', ...
            'Focus image folder does not exist.');
    end

    entries = dir(folder);
    keep = false(numel(entries), 1);
    for k = 1:numel(entries)
        entry = entries(k);
        if entry.isdir
            continue;
        end
        keep(k) = focus_stack.io.isSupportedImagePath(entry.name);
    end
    entries = entries(keep);

    paths = strings(numel(entries), 1);
    for k = 1:numel(entries)
        paths(k) = string(fullfile(folder, entries(k).name));
    end
    paths = focus_stack.io.sortPathsByName(paths);
    if numel(paths) < 2
        error('labkit_FocusStack_app:NotEnoughImages', ...
            'Focus stacking requires at least two image files in the selected folder.');
    end
end
