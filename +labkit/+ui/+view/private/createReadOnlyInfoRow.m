% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
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
