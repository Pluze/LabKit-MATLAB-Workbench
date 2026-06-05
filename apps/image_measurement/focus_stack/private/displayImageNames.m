% App-owned focus-stack display-name helper. Expected caller:
% labkit_FocusStack_app list refresh. Input is a path vector. Output is a cell
% column of display names. This helper has no side effects.
function names = displayImageNames(paths)
%DISPLAYIMAGENAMES Return display names for focus-stack paths.

    paths = string(paths(:));
    names = cell(numel(paths), 1);
    for k = 1:numel(paths)
        names{k} = displayNameFromPath(paths(k));
    end
end
