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
        [gridSize, rowHeight, rowMap] = expandedTabGridSpec(spec);
        grid = uigridlayout(panel, gridSize);
        enableScrollableGrid(grid);
        grid.RowHeight = rowHeight;
        grid.RowSpacing = optionValue(spec, 'rowSpacing', 10);
        grid.Padding = optionValue(spec, 'padding', [8 8 8 8]);
        grid.UserData = struct('LabKitLogicalRowMap', rowMap);
        if isfield(spec, 'columnWidth')
            grid.ColumnWidth = spec.columnWidth;
        end
        if isfield(spec, 'columnSpacing')
            grid.ColumnSpacing = spec.columnSpacing;
        end

        ui.([spec.key 'Tab']) = tab;
        ui.([spec.key 'ScrollPanel']) = panel;
        ui.([spec.key 'Grid']) = grid;
        ui.([spec.key 'ResizeHandles']) = attachTabRowResizeHandles(ui.fig, grid, spec, rowMap);
    end

    ui.rightPanel = uipanel(ui.main, 'Title', labels.rightPanel);
    ui.rightPanel.Layout.Row = 1;
    ui.rightPanel.Layout.Column = 3;

    ui.rightGrid = uigridlayout(ui.rightPanel, rightGridSize);
    ui.rightGrid.RowHeight = rightRowHeight;
    ui.rightGrid.ColumnWidth = {'1x'};
    ui.rightGrid.RowSpacing = rightRowSpacing;
    ui.rightGrid.Padding = [8 8 8 8];

    attachColumnResize(ui.fig, ui.main, 1, 2, ...
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

function enableScrollableGrid(grid)
    try
        grid.Scrollable = 'on';
    catch
    end
end

function [gridSize, rowHeight, rowMap] = expandedTabGridSpec(spec)
    logicalRows = spec.gridSize(1);
    resizeRows = validResizeRows(spec, logicalRows);
    rowMap = zeros(1, logicalRows);
    rowHeight = {};
    handleHeight = 6;
    if isfield(spec, 'resizeOptions') && isfield(spec.resizeOptions, 'handleHeight')
        handleHeight = spec.resizeOptions.handleHeight;
    end

    for row = 1:logicalRows
        rowMap(row) = numel(rowHeight) + 1;
        rowHeight{end+1} = spec.rowHeight{row}; %#ok<AGROW>
        if any(resizeRows == row)
            rowHeight{end+1} = handleHeight; %#ok<AGROW>
        end
    end
    gridSize = [numel(rowHeight), spec.gridSize(2)];
end

function rows = validResizeRows(spec, logicalRows)
    rows = [];
    if ~isfield(spec, 'resizeRows') || isempty(spec.resizeRows)
        return;
    end
    rows = unique(spec.resizeRows(:).');
    rows = rows(rows >= 1 & rows < logicalRows & isfinite(rows));
end

function handles = attachTabRowResizeHandles(fig, grid, spec, rowMap)
    handles = gobjects(0);
    resizeRows = validResizeRows(spec, spec.gridSize(1));
    if isempty(resizeRows)
        return;
    end

    handles = gobjects(1, numel(resizeRows));
    for k = 1:numel(resizeRows)
        topRow = resizeRows(k);
        opts = struct('minTopHeight', 80, 'minBottomHeight', 80);
        if isfield(spec, 'resizeOptions')
            opts = mergeStruct(opts, spec.resizeOptions);
        end
        opts.topRow = rowMap(topRow);
        opts.bottomRow = rowMap(topRow + 1);
        handles(k) = labkit.ui.addRowResizeHandle(fig, grid, rowMap(topRow) + 1, opts);
    end
end

function out = mergeStruct(out, in)
    fields = fieldnames(in);
    for k = 1:numel(fields)
        out.(fields{k}) = in.(fields{k});
    end
end
