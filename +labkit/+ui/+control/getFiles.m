function files = getFiles(ui, id)
%GETFILES Return all file-entry structs from a filePanel control.
%
% App-facing contract:
%   files = labkit.ui.control.getFiles(ui, id)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create.
%   id - semantic id for a filePanel.
%
% Output:
%   files - file-entry struct array with id, index, path, name,
%       displayName, and optional status fields.

    control = resolveControl(ui, id);
    if ~isfield(control, 'kind') || ~strcmp(control.kind, 'filePanel') || ...
            ~isfield(control, 'currentFiles') || ...
            ~isa(control.currentFiles, 'function_handle')
        error('labkit:ui:control:NotFilePanel', ...
            'Control "%s" is not a filePanel.', control.id);
    end
    files = control.currentFiles();
end
