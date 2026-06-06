% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function [lbl, dd] = createLabeledDropdown(parent, labelText, varargin)
%CREATELABELEDDROPDOWN Create a right-aligned label followed by a dropdown.
%
% Inputs:
%   parent - parent grid.
%   labelText - visible label.
%   varargin - name/value arguments forwarded to uidropdown.
%
% Output:
%   lbl - uilabel handle.
%   dd - uidropdown handle.

    lbl = uilabel(parent, ...
        'Text', labelText, ...
        'HorizontalAlignment', 'right');
    dd = uidropdown(parent, varargin{:});
end
