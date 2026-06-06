% App-owned CIC top/bottom plot controls helper. Expected caller:
% cic.ui.buildControls. Inputs are parent panels, axis items, default
% selections, and a value-change callback. Output is a controls struct with
% handles plus setSelections/swapSelections closures. Side effects are limited
% to creating controls on the supplied panels.
function ui = topBottomPlotControls(topPanel, bottomPanel, xItems, yItems, topDefaults, bottomDefaults, valueChangedFcn)
%TOPBOTTOMPLOTCONTROLS Create CIC top/bottom plot controls.

    if nargin < 7
        valueChangedFcn = [];
    end

    ui = struct();
    [ui.topGrid, ui.topX, ui.topY, ui.topGridCheckbox] = createOneRow( ...
        topPanel, xItems, yItems, topDefaults, valueChangedFcn);
    [ui.bottomGrid, ui.bottomX, ui.bottomY, ui.bottomGridCheckbox] = createOneRow( ...
        bottomPanel, xItems, yItems, bottomDefaults, valueChangedFcn);
    ui.setSelections = @setSelections;
    ui.swapSelections = @swapSelections;

    function setSelections(topSelection, bottomSelection)
        applySelection(ui.topX, ui.topY, topSelection);
        applySelection(ui.bottomX, ui.bottomY, bottomSelection);
    end

    function swapSelections()
        topSelection = struct('x', ui.topX.Value, 'y', ui.topY.Value);
        bottomSelection = struct('x', ui.bottomX.Value, 'y', ui.bottomY.Value);
        setSelections(bottomSelection, topSelection);
    end
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

function applySelection(ddX, ddY, selection)
    if isfield(selection, 'x') && any(strcmp(ddX.Items, selection.x))
        ddX.Value = selection.x;
    end
    if isfield(selection, 'y') && any(strcmp(ddY.Items, selection.y))
        ddY.Value = selection.y;
    end
end
