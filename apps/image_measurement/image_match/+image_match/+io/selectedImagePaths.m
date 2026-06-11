% Expected caller: labkit_ImageMatch_app and image_match IO tests. Inputs
% are uigetfile selected names and folder. Output is a sorted string column of
% absolute file paths. Unsupported extensions raise an app-specific error.
function paths = selectedImagePaths(files, folder)

    folder = string(folder);
    if ischar(files) || isstring(files)
        files = {char(files)};
    end

    paths = strings(numel(files), 1);
    for k = 1:numel(files)
        paths(k) = string(fullfile(char(folder), char(files{k})));
    end
    paths = sort(paths(:));

    allowed = image_match.io.supportedImageExtensions();
    for k = 1:numel(paths)
        [~, ~, ext] = fileparts(char(paths(k)));
        if ~any(strcmpi(string(ext), allowed))
            error('labkit_ImageMatch_app:UnsupportedImageFile', ...
                'Unsupported image file type: %s', char(paths(k)));
        end
    end
end
