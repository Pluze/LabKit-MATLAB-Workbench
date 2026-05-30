function ui = createTopBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, valueChangedFcn)
%CREATETOPBOTTOMPLOTCONTROLS Create shared top/bottom plot controls.

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
