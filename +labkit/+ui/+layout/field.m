function layout = field(id, labelText, varargin)
%FIELD Create a labeled scalar field layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.field(id, label, "kind", kind, "value", value, ...)
%
% Inputs:
%   id - globally unique field id.
%   labelText - field label.
%   kind - one of text, number, spinner, dropdown, slider, checkbox, readonly.
%   value, items, limits, step, unit, tooltip, onChange - optional props.
%
% Output:
%   layout - scalar data-only UI layout struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.kind = char(string(optionValue(props, 'kind', 'text')));
    validateFieldKind(props.kind);
    layout = makeLayoutNode('field', id, props, {}, struct());
end

function validateFieldKind(kind)
    allowed = {'text', 'number', 'spinner', 'dropdown', 'slider', ...
        'checkbox', 'readonly'};
    if ~any(strcmpi(kind, allowed))
        error('labkit:ui:layout:InvalidFieldKind', ...
            'Unsupported UI 5 field kind "%s".', kind);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
