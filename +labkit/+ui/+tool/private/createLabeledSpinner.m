% Private scale-bar/tool control helper. Expected caller: labkit.ui.tool
% private panels. Inputs are a parent grid, visible label text, and uispinner
% name/value arguments; outputs are label and spinner handles. Side effects
% are limited to creating UI controls under the parent.
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
