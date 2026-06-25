function setFileSelection(ui, id, filesOrIds)
%SETFILESELECTION Select filePanel entries by file structs or ids.
%
% App-facing contract:
%   labkit.ui.view.setFileSelection(ui, id, filesOrIds)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - semantic id for a filePanel.
%   filesOrIds - file-entry structs emitted by filePanel/getFiles, or
%       string/cell file ids.
%
% Output:
%   None. The filePanel list selection is updated without invoking the app
%   selection callback.

    control = resolveControl(ui, id);
    if ~isfield(control, 'kind') || ~strcmp(control.kind, 'filePanel') || ...
            ~isfield(control, 'setFileSelection') || ...
            ~isa(control.setFileSelection, 'function_handle')
        error('labkit:ui:view:NotFilePanel', ...
            'Control "%s" is not a filePanel.', control.id);
    end
    control.setFileSelection(control, filesOrIds);
end
