function [field, lbl] = createReadOnlyInfoRow(parent, row, labelText)
%CREATEREADONLYINFOROW Create a labeled read-only text field row.
%
% Inputs:
%   parent - parent grid.
%   row - row inside parent.
%   labelText - visible label.
%
% Output:
%   field - read-only text field initialized to "-".
%   lbl - label handle.

    [lbl, field] = createLabeledEditField(parent, labelText, 'text', ...
        'Editable', 'off', ...
        'Value', '-');
    lbl.Layout.Row = row;
    lbl.Layout.Column = 1;
    field.Layout.Row = row;
    field.Layout.Column = 2;
end
