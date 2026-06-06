% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function [lbl, spinner] = createLabeledSpinner(parent, labelText, varargin)
%CREATELABELEDSPINNER Create a right-aligned label followed by a spinner.
%
% Inputs:
%   parent - parent grid.
%   labelText - visible label.
%   varargin - name/value arguments forwarded to uispinner.
%
% Output:
%   lbl - uilabel handle.
%   spinner - uispinner handle.

    lbl = uilabel(parent, ...
        'Text', labelText, ...
        'HorizontalAlignment', 'right');
    spinner = uispinner(parent, varargin{:});
end
