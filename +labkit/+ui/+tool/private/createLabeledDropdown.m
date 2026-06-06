% Private scale-bar/tool control helper. Expected caller: labkit.ui.tool
% private panels. Inputs are a parent grid, visible label text, and uidropdown
% name/value arguments; outputs are label and dropdown handles. Side effects
% are limited to creating UI controls under the parent.
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
