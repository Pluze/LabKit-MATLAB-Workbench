% Private scale-bar/interaction readout helper. Expected caller: labkit.ui.interaction
% private panels. Inputs are a parent grid, target row, and visible label;
% outputs are a read-only text field and label handles. Side effects are
% limited to creating and placing UI controls under the parent.
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
