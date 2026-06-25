function paths = filePaths(files)
%FILEPATHS Return paths from filePanel file-entry structs.
%
% App-facing contract:
%   paths = labkit.ui.view.filePaths(files)
%
% Inputs:
%   files - file-entry struct array emitted by filePanel events or assigned
%       to a filePanel value. Entries must expose path.
%
% Output:
%   paths - string column of nonempty path values.

    if isempty(files)
        paths = strings(0, 1);
        return;
    end
    if ~isstruct(files) || ~isfield(files, 'path')
        error('labkit:ui:view:InvalidFileStruct', ...
            'filePaths expects file-entry structs with a path field.');
    end
    paths = string({files.path}).';
    paths = paths(strlength(paths) > 0);
end
