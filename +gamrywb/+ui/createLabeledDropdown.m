function [lbl, dd] = createLabeledDropdown(parent, labelText, varargin)
%CREATELABELEDDROPDOWN Create a right-aligned label followed by a dropdown.

    lbl = uilabel(parent, ...
        'Text', labelText, ...
        'HorizontalAlignment', 'right');
    dd = uidropdown(parent, varargin{:});
end
