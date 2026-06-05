function place(component, parent, row, column)
%PLACE Place a component on a LabKit logical shell row.
%
% Inputs:
%   component - MATLAB UI component with a Layout property.
%   parent - parent grid. Shell tab grids may contain a private logical row
%       map inserted by labkit.ui.app.createShell.
%   row - logical row in the parent grid.
%   column - optional Layout.Column value.
%
% Output:
%   Mutates component.Layout.Row and optionally component.Layout.Column.

    if isempty(component) || ~isvalid(component)
        return;
    end
    component.Layout.Row = layoutRow(parent, row);
    if nargin >= 4 && ~isempty(column)
        component.Layout.Column = column;
    end
end
