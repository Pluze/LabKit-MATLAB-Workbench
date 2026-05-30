function ui = createTabbedWorkbenchShell(figName, figPosition, leftWidth, labels, tabSpecs, rightGridSize, rightRowHeight, rightRowSpacing)
%CREATETABBEDWORKBENCHSHELL Create the shared resizable tabbed workbench shell.

    ui = struct();
    ui.fig = uifigure('Name', figName, 'Position', figPosition);

    ui.main = uigridlayout(ui.fig, [1 3]);
    ui.main.ColumnWidth = {leftWidth, 6, '1x'};
    ui.main.RowHeight = {'1x'};
    ui.main.Padding = [10 10 10 10];
    ui.main.ColumnSpacing = 0;

    ui.separator = uipanel(ui.main, ...
        'BackgroundColor', [0.75 0.75 0.75], ...
        'BorderType', 'none');
    ui.separator.Layout.Row = 1;
    ui.separator.Layout.Column = 2;

    ui.leftPanel = uipanel(ui.main, 'Title', labels.controlsPanel);
    ui.leftPanel.Layout.Row = 1;
    ui.leftPanel.Layout.Column = 1;

    ui.leftHost = uigridlayout(ui.leftPanel, [1 1]);
    ui.leftHost.RowHeight = {'1x'};
    ui.leftHost.ColumnWidth = {'1x'};
    ui.leftHost.Padding = [8 8 8 8];

    ui.tabs = uitabgroup(ui.leftHost);
    ui.tabs.Layout.Row = 1;
    ui.tabs.Layout.Column = 1;

    for k = 1:numel(tabSpecs)
        spec = tabSpecs(k);
        [tab, panel] = createScrollableTab(ui.tabs, spec.title);
        grid = uigridlayout(panel, spec.gridSize);
        grid.RowHeight = spec.rowHeight;
        grid.RowSpacing = optionValue(spec, 'rowSpacing', 10);
        grid.Padding = optionValue(spec, 'padding', [8 8 8 8]);
        if isfield(spec, 'columnWidth')
            grid.ColumnWidth = spec.columnWidth;
        end
        if isfield(spec, 'columnSpacing')
            grid.ColumnSpacing = spec.columnSpacing;
        end

        ui.([spec.key 'Tab']) = tab;
        ui.([spec.key 'ScrollPanel']) = panel;
        ui.([spec.key 'Grid']) = grid;
    end

    ui.rightPanel = uipanel(ui.main, 'Title', labels.rightPanel);
    ui.rightPanel.Layout.Row = 1;
    ui.rightPanel.Layout.Column = 3;

    ui.rightGrid = uigridlayout(ui.rightPanel, rightGridSize);
    ui.rightGrid.RowHeight = rightRowHeight;
    ui.rightGrid.ColumnWidth = {'1x'};
    ui.rightGrid.RowSpacing = rightRowSpacing;
    ui.rightGrid.Padding = [8 8 8 8];

    labkit.ui.attachColumnResize(ui.fig, ui.main, 1, 2, ...
        struct('minWidth', 260, 'rightReserve', 360, 'separatorWidth', 6));
end

function [tab, panel] = createScrollableTab(parent, titleText)
    tab = uitab(parent, 'Title', titleText);
    host = uigridlayout(tab, [1 1]);
    host.RowHeight = {'1x'};
    host.ColumnWidth = {'1x'};
    host.Padding = [0 0 0 0];

    panel = uipanel(host, ...
        'BorderType', 'none', ...
        'Scrollable', 'on');
    panel.Layout.Row = 1;
    panel.Layout.Column = 1;
end

function value = optionValue(s, name, defaultValue)
    value = defaultValue;
    if isfield(s, name)
        value = s.(name);
    end
end
