% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
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
