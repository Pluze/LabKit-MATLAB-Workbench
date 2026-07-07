% Private UI runtime helper. Expected caller: labkit.ui.runtime shell construction
% code. Inputs and outputs are internal uifigure, grid, tab, or resize handle
% values. Side effects are limited to UI object creation or callback wiring on
% supplied parents; assumes the caller owns component lifecycle.
function ui = createTabbedWorkbenchShell(figName, figPosition, leftWidth, labels, tabLayouts, rightGridSize, rightRowHeight, rightRowSpacing, debug, utilities)
%CREATETABBEDWORKBENCHSHELL Build the private tabbed workbench skeleton.
%
% Called by:
%   labkit.ui.runtime.create through buildShellFromLayout.
%
% Inputs:
%   figName - figure name/title.
%   figPosition - uifigure Position vector.
%   leftWidth - initial fixed width of the left control panel.
%   labels - struct with controlsPanel and rightPanel text.
%   tabLayouts - internal tab layouts derived from UI 5 workbench layouts.
%   rightGridSize - right-side uigridlayout size.
%   rightRowHeight - right-side grid RowHeight cell array.
%   rightRowSpacing - right-side grid RowSpacing scalar.
%
% Output:
%   ui - workbench handle struct containing fig, main grid, left/right
%        panels, tabs, scroll panels, tab grids, resize handles, and rightGrid.
%
% Notes:
%   Logical tab rows are expanded with physical resize-handle rows here.
%   App code should use UI 5 layouts rather than depending on physical row
%   indices.

    if nargin < 9
        debug = [];
    end
    if nargin < 10
        utilities = struct();
    end

    ui = struct();
    figArgs = {'Name', figName, 'Position', figPosition};
    if guiTestMode() == "hidden"
        figArgs = [figArgs, {'Visible', 'off'}];
    end
    ui.fig = uifigure(figArgs{:});
    installCloseKeyboardShortcut(ui.fig);
    applyGuiTestMode(ui.fig);
    paintVisibleFigure();

    ui.main = uigridlayout(ui.fig, [3 3]);
    ui.main.ColumnWidth = {leftWidth, 6, '1x'};
    ui.main.RowHeight = {utilityRowHeight(utilities), 0, '1x'};
    ui.main.Padding = [10 10 10 10];
    ui.main.ColumnSpacing = 0;
    ui.main.RowSpacing = 6;

    ui.utilityBarPanel = createUtilityBar(ui.fig, ui.main, utilities);
    ui.utilityBarPanel.Layout.Row = 1;
    ui.utilityBarPanel.Layout.Column = [1 3];

    ui.startupStatusPanel = uipanel(ui.main, ...
        'BackgroundColor', [0.94 0.97 1.00], ...
        'BorderType', 'none', ...
        'Visible', 'off');
    ui.startupStatusPanel.Layout.Row = 2;
    ui.startupStatusPanel.Layout.Column = [1 3];

    startupGrid = uigridlayout(ui.startupStatusPanel, [1 1]);
    startupGrid.RowHeight = {'1x'};
    startupGrid.ColumnWidth = {'1x'};
    startupGrid.Padding = [8 3 8 3];
    ui.startupStatusLabel = uilabel(startupGrid, ...
        'Text', 'Starting...', ...
        'FontWeight', 'bold');
    ui.startupStatusLabel.Layout.Row = 1;
    ui.startupStatusLabel.Layout.Column = 1;

    ui.separator = uipanel(ui.main, ...
        'BackgroundColor', [0.75 0.75 0.75], ...
        'BorderType', 'none');
    ui.separator.Layout.Row = 3;
    ui.separator.Layout.Column = 2;

    ui.leftPanel = uipanel(ui.main, 'Title', labels.controlsPanel);
    ui.leftPanel.Layout.Row = 3;
    ui.leftPanel.Layout.Column = 1;

    ui.leftHost = uigridlayout(ui.leftPanel, [1 1]);
    ui.leftHost.RowHeight = {'1x'};
    ui.leftHost.ColumnWidth = {'1x'};
    ui.leftHost.Padding = [8 8 8 8];

    ui.tabs = uitabgroup(ui.leftHost);
    ui.tabs.Layout.Row = 1;
    ui.tabs.Layout.Column = 1;

    for k = 1:numel(tabLayouts)
        tabLayout = tabLayouts(k);
        [tab, panel] = createScrollableTab(ui.tabs, tabLayout.title);
        [gridSize, rowHeight, rowMap] = expandedTabGridLayout(tabLayout);
        grid = uigridlayout(panel, gridSize);
        enableScrollableGrid(grid);
        grid.RowHeight = rowHeight;
        grid.RowSpacing = optionValue(tabLayout, 'rowSpacing', 10);
        grid.Padding = optionValue(tabLayout, 'padding', [8 8 8 8]);
        grid.UserData = struct('LabKitLogicalRowMap', rowMap);
        if isfield(tabLayout, 'columnWidth')
            grid.ColumnWidth = tabLayout.columnWidth;
        end
        if isfield(tabLayout, 'columnSpacing')
            grid.ColumnSpacing = tabLayout.columnSpacing;
        end

        ui.([tabLayout.key 'Tab']) = tab;
        ui.([tabLayout.key 'ScrollPanel']) = panel;
        ui.([tabLayout.key 'Grid']) = grid;
        ui.([tabLayout.key 'ResizeHandles']) = attachTabRowResizeHandles( ...
            ui.fig, grid, tabLayout, rowMap, debugTrace(debug));
    end

    ui.rightPanel = uipanel(ui.main, 'Title', labels.rightPanel);
    ui.rightPanel.Layout.Row = 3;
    ui.rightPanel.Layout.Column = 3;

    ui.rightGrid = uigridlayout(ui.rightPanel, rightGridSize);
    ui.rightGrid.RowHeight = rightRowHeight;
    ui.rightGrid.ColumnWidth = {'1x'};
    ui.rightGrid.RowSpacing = rightRowSpacing;
    ui.rightGrid.Padding = [8 8 8 8];

    attachColumnResize(ui.fig, ui.main, 1, 2, ...
        struct('minWidth', 260, 'rightReserve', 360, 'separatorWidth', 6, ...
        'onTrace', debugTrace(debug)));
end

function height = utilityRowHeight(~)
    height = 0;
end

function mode = guiTestMode()
    mode = lower(strtrim(string(getenv('LABKIT_GUI_TEST_MODE'))));
    if ~any(mode == ["hidden", "minimized"])
        mode = "visible";
    end
end

function applyGuiTestMode(fig)
    if guiTestMode() == "minimized" && isprop(fig, 'WindowState')
        try
            fig.WindowState = 'minimized';
        catch
        end
    end
end

function paintVisibleFigure()
    if guiTestMode() ~= "visible"
        return;
    end
    drawnow limitrate;
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

function [gridSize, rowHeight, rowMap] = expandedTabGridLayout(tabLayout)
    logicalRows = tabLayout.gridSize(1);
    resizeRows = validResizeRows(tabLayout, logicalRows);
    rowMap = zeros(1, logicalRows);
    rowHeight = {};
    handleHeight = 6;
    if isfield(tabLayout, 'resizeOptions') && isfield(tabLayout.resizeOptions, 'handleHeight')
        handleHeight = tabLayout.resizeOptions.handleHeight;
    end

    for row = 1:logicalRows
        rowMap(row) = numel(rowHeight) + 1;
        rowHeight{end+1} = tabLayout.rowHeight{row};
        if any(resizeRows == row)
            rowHeight{end+1} = handleHeight;
        end
    end
    gridSize = [numel(rowHeight), tabLayout.gridSize(2)];
end

function rows = validResizeRows(tabLayout, logicalRows)
    rows = [];
    if isfield(tabLayout, 'resizeRows') && ~isempty(tabLayout.resizeRows)
        rows = unique(tabLayout.resizeRows(:).');
        rows = rows(rows >= 1 & rows <= logicalRows & isfinite(rows));
        return;
    end

    mode = optionValue(tabLayout, 'resize', 'betweenRows');
    if islogical(mode)
        if mode
            rows = 1:logicalRows;
        end
        return;
    end
    mode = lower(char(string(mode)));
    switch mode
        case {'betweenrows', 'auto', 'all'}
            rows = 1:logicalRows;
        case {'none', 'off', 'false'}
            rows = [];
        otherwise
            error('labkit:ui:InvalidTabResizeMode', ...
                'Unsupported tab resize mode "%s".', char(string(mode)));
    end
    rows = rows(rows >= 1 & rows <= logicalRows & isfinite(rows));
end

function handles = attachTabRowResizeHandles(fig, grid, tabLayout, rowMap, traceCallback)
    handles = gobjects(0);
    resizeRows = validResizeRows(tabLayout, tabLayout.gridSize(1));
    if isempty(resizeRows)
        return;
    end

    handles = gobjects(1, numel(resizeRows));
    for k = 1:numel(resizeRows)
        topRow = resizeRows(k);
        opts = struct('minTopHeight', 80);
        if isfield(tabLayout, 'resizeOptions')
            opts = mergeStruct(opts, tabLayout.resizeOptions);
        end
        opts.topRow = rowMap(topRow);
        opts.onTrace = traceCallback;
        handles(k) = addRowResizeHandle(fig, grid, rowMap(topRow) + 1, opts);
    end
end

function callback = debugTrace(debug)
    callback = [];
    if isstruct(debug) && isfield(debug, 'trace') && ...
            isa(debug.trace, 'function_handle')
        callback = debug.trace;
    end
end

function installCloseKeyboardShortcut(fig)
    if ~isprop(fig, 'WindowKeyPressFcn')
        return;
    end
    previous = fig.WindowKeyPressFcn;
    setappdata(fig, 'labkitUiCloseShortcutPreviousKeyFcn', previous);
    fig.WindowKeyPressFcn = @(source, event) closeShortcutKeyPress(source, event);
end

function closeShortcutKeyPress(fig, event)
    if isCloseShortcut(event)
        requestFigureClose(fig, event);
        return;
    end

    previous = [];
    if isvalid(fig) && isappdata(fig, 'labkitUiCloseShortcutPreviousKeyFcn')
        previous = getappdata(fig, 'labkitUiCloseShortcutPreviousKeyFcn');
    end
    runPreviousKeyPress(previous, fig, event);
end

function tf = isCloseShortcut(event)
    tf = false;
    if ~hasEventValue(event, 'Key')
        return;
    end
    key = lower(string(eventValue(event, 'Key')));
    if key ~= "w"
        return;
    end
    modifiers = strings(0, 1);
    if hasEventValue(event, 'Modifier')
        modifiers = lower(string(eventValue(event, 'Modifier')));
    end
    tf = any(modifiers == "command") || any(modifiers == "control");
end

function tf = hasEventValue(event, name)
    if isstruct(event)
        tf = isfield(event, name);
    else
        tf = isprop(event, name);
    end
end

function value = eventValue(event, name)
    value = event.(name);
end

function requestFigureClose(fig, event)
    if ~isvalid(fig)
        return;
    end
    closeFcn = fig.CloseRequestFcn;
    if isa(closeFcn, 'function_handle')
        closeFcn(fig, event);
    elseif ischar(closeFcn) || (isstring(closeFcn) && isscalar(closeFcn))
        eval(char(closeFcn));
    else
        delete(fig);
    end
end

function runPreviousKeyPress(previous, fig, event)
    if isempty(previous)
        return;
    end
    if isa(previous, 'function_handle')
        previous(fig, event);
    elseif ischar(previous) || (isstring(previous) && isscalar(previous))
        eval(char(previous));
    end
end

function out = mergeStruct(out, in)
    fields = fieldnames(in);
    for k = 1:numel(fields)
        out.(fields{k}) = in.(fields{k});
    end
end
