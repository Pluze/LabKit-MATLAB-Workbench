function field = createReadOnlyTextField(parent, varargin)
%CREATEREADONLYTEXTFIELD Create a read-only single-line text field.

    field = uieditfield(parent, 'text', ...
        'Editable', 'off', ...
        varargin{:});
end
