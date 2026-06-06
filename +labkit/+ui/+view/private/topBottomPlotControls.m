% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function ui = topBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, valueChangedFcn)
%CREATETOPBOTTOMPLOTCONTROLS Create shared top/bottom plot controls.
%
% Inputs:
%   topPanel, bottomPanel - parent panels for control rows.
%   xItems, yItems - dropdown items for X and Y axes.
%   topDefaults, bottomDefaults - structs with x and y default values.
%   valueChangedFcn - optional callback for dropdowns/grid checkboxes.
%
% Output:
%   ui - struct with top/bottom grids, X/Y dropdowns, and grid checkboxes.

    if nargin < 7
        valueChangedFcn = [];
    end

    ui = struct();
    [ui.topGrid, ui.topX, ui.topY, ui.topGridCheckbox] = createOneRow( ...
        topPanel, xItems, yItems, topDefaults, valueChangedFcn);
    [ui.bottomGrid, ui.bottomX, ui.bottomY, ui.bottomGridCheckbox] = createOneRow( ...
        bottomPanel, xItems, yItems, bottomDefaults, valueChangedFcn);
end

function [grid, ddX, ddY, cbGrid] = createOneRow(parent, xItems, yItems, defaults, valueChangedFcn)
    grid = uigridlayout(parent, [1 5]);
    grid.ColumnWidth = {'fit', '1x', 'fit', '1x', '1x'};
    grid.Padding = [8 6 8 6];
    grid.ColumnSpacing = 8;

    uilabel(grid, 'Text', 'X:', 'HorizontalAlignment', 'right');
    ddX = uidropdown(grid, ...
        'Items', xItems, ...
        'Value', defaults.x, ...
        'ValueChangedFcn', valueChangedFcn);

    uilabel(grid, 'Text', 'Y:', 'HorizontalAlignment', 'right');
    ddY = uidropdown(grid, ...
        'Items', yItems, ...
        'Value', defaults.y, ...
        'ValueChangedFcn', valueChangedFcn);

    cbGrid = uicheckbox(grid, ...
        'Text', 'Grid', ...
        'Value', defaults.grid, ...
        'ValueChangedFcn', valueChangedFcn);
end
