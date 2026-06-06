% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
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
