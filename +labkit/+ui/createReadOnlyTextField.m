function field = createReadOnlyTextField(parent, varargin)
%CREATEREADONLYTEXTFIELD Create a read-only single-line text field.
%
% Inputs:
%   parent - parent grid.
%   varargin - name/value arguments forwarded to uieditfield.
%
% Output:
%   field - read-only text uieditfield handle.

    field = uieditfield(parent, 'text', ...
        'Editable', 'off', ...
        varargin{:});
end
