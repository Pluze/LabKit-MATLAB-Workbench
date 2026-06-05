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
