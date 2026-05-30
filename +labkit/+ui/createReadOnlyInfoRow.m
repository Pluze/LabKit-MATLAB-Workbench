function [field, lbl] = createReadOnlyInfoRow(parent, row, labelText)
%CREATEREADONLYINFOROW Create a labeled read-only text field row.

    [lbl, field] = labkit.ui.createLabeledEditField(parent, labelText, 'text', ...
        'Editable', 'off', ...
        'Value', '-');
    lbl.Layout.Row = row;
    lbl.Layout.Column = 1;
    field.Layout.Row = row;
    field.Layout.Column = 2;
end
