function spec = pathPanel(id, labelText, varargin)
%PATHPANEL Create a file/folder chooser panel spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.pathPanel(id, label, "mode", mode, callbacks...)
%
% Inputs:
%   id - globally unique path-panel id.
%   labelText - panel label.
%   mode - singleFile, multiFile, folder, multiFolder, or outputFolder.
%   filters, status, emptyText, onChoose, onRemove, onClear - optional props.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.mode = char(string(optionValue(props, 'mode', 'singleFile')));
    validateMode(props.mode);
    spec = makeSpec('pathPanel', id, props, {}, struct());
end

function validateMode(mode)
    allowed = {'singleFile', 'multiFile', 'folder', 'multiFolder', 'outputFolder'};
    if ~any(strcmp(mode, allowed))
        error('labkit:ui:spec:InvalidPathPanelMode', ...
            'Unsupported pathPanel mode "%s".', mode);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
