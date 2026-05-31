function [lbl, spinner] = createLabeledSpinner(parent, labelText, varargin)
%CREATELABELEDSPINNER Create a right-aligned label followed by a spinner.

    lbl = uilabel(parent, ...
        'Text', labelText, ...
        'HorizontalAlignment', 'right');
    spinner = uispinner(parent, varargin{:});
end
