function spec = field(id, labelText, varargin)
%FIELD Create a labeled scalar field spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.field(id, label, "kind", kind, "value", value, ...)
%
% Inputs:
%   id - globally unique field id.
%   labelText - field label.
%   kind - one of text, number, spinner, dropdown, slider, checkbox, readonly.
%   value, items, limits, step, unit, tooltip, onChange - optional props.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.kind = char(string(optionValue(props, 'kind', 'text')));
    validateFieldKind(props.kind);
    spec = makeSpec('field', id, props, {}, struct());
end

function validateFieldKind(kind)
    allowed = {'text', 'number', 'spinner', 'dropdown', 'slider', ...
        'checkbox', 'readonly'};
    if ~any(strcmpi(kind, allowed))
        error('labkit:ui:spec:InvalidFieldKind', ...
            'Unsupported UI 2.0 field kind "%s".', kind);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
