function [lbl, field] = createLabeledEditField(parent, labelText, style, varargin)
%CREATELABELEDEDITFIELD Create a right-aligned label followed by an edit field.

    lbl = uilabel(parent, ...
        'Text', labelText, ...
        'HorizontalAlignment', 'right');
    field = uieditfield(parent, style, varargin{:});
end
