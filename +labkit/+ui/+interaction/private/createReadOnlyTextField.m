% Private scale-bar/interaction readout helper. Expected caller: labkit.ui.interaction
% private panels. Inputs are a parent grid and uieditfield name/value
% arguments; output is a read-only text field handle. Side effects are limited
% to creating one UI control under the parent.
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
