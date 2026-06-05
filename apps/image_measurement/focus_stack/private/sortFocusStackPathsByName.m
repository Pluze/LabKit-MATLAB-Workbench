% App-owned focus-stack path sorting helper. Expected caller: focus-stack app
% private loading helpers. Input is a path vector. Output is a string column
% sorted by base filename plus extension.
function paths = sortFocusStackPathsByName(paths)
%SORTFOCUSSTACKPATHSBYNAME Sort focus-stack paths by case-insensitive name.
% Expected caller: focus-stack app private loading helpers. Input is a path
% vector. Output is a string column sorted by base filename plus extension.

    paths = string(paths(:));
    names = strings(numel(paths), 1);
    for k = 1:numel(paths)
        [~, base, ext] = fileparts(char(paths(k)));
        names(k) = lower(string([base ext]));
    end
    [~, order] = sort(names);
    paths = paths(order);
end
