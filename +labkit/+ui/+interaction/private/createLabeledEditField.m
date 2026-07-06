% Private scale-bar/interaction control helper. Expected caller: labkit.ui.interaction
% private panels. Inputs are a parent grid, visible label text, edit style,
% and uieditfield name/value arguments; outputs are label and field handles.
% Side effects are limited to creating UI controls under the parent.
function [lbl, field] = createLabeledEditField(parent, labelText, style, varargin)
%CREATELABELEDEDITFIELD Create a right-aligned label followed by an edit field.
%
% Inputs:
%   parent - parent grid.
%   labelText - visible label.
%   style - uieditfield style, for example "text" or "numeric".
%   varargin - name/value arguments forwarded to uieditfield.
%
% Output:
%   lbl - uilabel handle.
%   field - uieditfield handle.

    lbl = uilabel(parent, ...
        'Text', labelText, ...
        'HorizontalAlignment', 'right');
    field = uieditfield(parent, style, varargin{:});
end
