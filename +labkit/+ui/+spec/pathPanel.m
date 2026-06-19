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
%   selectionMode - single or multiple list selection behavior. Defaults to
%       multiple for multiFile/multiFolder and single otherwise.
%   filters, chooseLabel, clearLabel, status, emptyText, minRows, minHeight,
%       onChoose, onSelectionChange, onClear - optional props. emptyText
%       defaults to a mode-aware prompt, or to status when status is supplied.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.mode = char(string(optionValue(props, 'mode', 'singleFile')));
    validateMode(props.mode);
    props.selectionMode = char(string(optionValue(props, ...
        'selectionMode', defaultSelectionMode(props.mode))));
    validateSelectionMode(props.selectionMode);
    spec = makeSpec('pathPanel', id, props, {}, struct());
end

function validateMode(mode)
    allowed = {'singleFile', 'multiFile', 'folder', 'multiFolder', 'outputFolder'};
    if ~any(strcmp(mode, allowed))
        error('labkit:ui:spec:InvalidPathPanelMode', ...
            'Unsupported pathPanel mode "%s".', mode);
    end
end

function validateSelectionMode(mode)
    allowed = {'single', 'multiple'};
    if ~any(strcmp(mode, allowed))
        error('labkit:ui:spec:InvalidPathPanelSelectionMode', ...
            'Unsupported pathPanel selectionMode "%s".', mode);
    end
end

function mode = defaultSelectionMode(pathMode)
    if any(strcmp(pathMode, {'multiFile', 'multiFolder'}))
        mode = 'multiple';
    else
        mode = 'single';
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
