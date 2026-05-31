function ui = createPanelGrid(parent, titleText, row, gridSize, opts)
%CREATEPANELGRID Create a standard titled panel containing a grid layout.
%
% Usage:
%   ui = labkit.ui.createPanelGrid(parent, 'Inputs', 1, [3 2]);
%   ui = labkit.ui.createPanelGrid(parent, 'Inputs', 1, [3 2], ...
%       struct('rowHeight', {{'fit','fit','1x'}}, 'columnWidth', {{120,'1x'}}));
%
% Inputs:
%   parent - uigridlayout or compatible MATLAB UI parent.
%   titleText - panel title.
%   row - logical parent row. Use [] when caller assigns Layout manually.
%   gridSize - child grid size [rows columns].
%   opts - optional struct.
%
% Options:
%   rowHeight - child grid RowHeight, default all {'fit'}.
%   columnWidth - child grid ColumnWidth, default all {'1x'}.
%   padding - child grid Padding, default [8 8 8 8].
%   rowSpacing - child grid RowSpacing, default 8.
%   columnSpacing - child grid ColumnSpacing, default 8.
%   autoGrowParentRow - logical, default true.
%   minPanelHeight - scalar minimum parent row height when auto-growing.
%
% Output:
%   ui - struct with panel and grid fields.

    if nargin < 5
        opts = struct();
    end

    ui = struct();
    ui.panel = uipanel(parent, 'Title', titleText);
    if nargin >= 3 && ~isempty(row)
        ui.panel.Layout.Row = labkit.ui.layoutRow(parent, row);
    end

    ui.grid = uigridlayout(ui.panel, gridSize);
    ui.grid.RowHeight = optionValue(opts, 'rowHeight', defaultRowHeight(gridSize));
    ui.grid.ColumnWidth = optionValue(opts, 'columnWidth', defaultColumnWidth(gridSize));
    ui.grid.Padding = optionValue(opts, 'padding', [8 8 8 8]);
    ui.grid.RowSpacing = optionValue(opts, 'rowSpacing', 8);
    ui.grid.ColumnSpacing = optionValue(opts, 'columnSpacing', 8);
    if exist('row', 'var') && ~isempty(row)
        autoGrowParentRow(parent, ui.panel.Layout.Row, gridSize, ui.grid, opts);
    end
end

function rowHeight = defaultRowHeight(gridSize)
    rowHeight = repmat({'fit'}, 1, gridSize(1));
end

function columnWidth = defaultColumnWidth(gridSize)
    if gridSize(2) == 2
        columnWidth = {'fit', '1x'};
    else
        columnWidth = repmat({'1x'}, 1, gridSize(2));
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end

function autoGrowParentRow(parent, row, gridSize, childGrid, opts)
    if ~optionValue(opts, 'autoGrowParentRow', true) || ...
            isempty(parent) || ~isvalid(parent) || ~isprop(parent, 'RowHeight')
        return;
    end

    rowHeights = parent.RowHeight;
    if isnumeric(rowHeights)
        rowHeights = num2cell(rowHeights);
    end
    if row > numel(rowHeights) || ~isnumeric(rowHeights{row})
        return;
    end

    minHeight = optionValue(opts, 'minPanelHeight', ...
        estimatePanelHeight(gridSize, childGrid.RowHeight, childGrid.RowSpacing, childGrid.Padding));
    if rowHeights{row} < minHeight
        rowHeights{row} = minHeight;
        parent.RowHeight = rowHeights;
    end
end

function height = estimatePanelHeight(gridSize, rowHeight, rowSpacing, padding)
    titleHeight = 24;
    defaultFitHeight = 24;
    defaultFlexHeight = 80;
    borderAllowance = 8;
    height = titleHeight + borderAllowance + padding(2) + padding(4);

    if ~iscell(rowHeight)
        rowHeight = num2cell(rowHeight);
    end
    for k = 1:gridSize(1)
        item = rowHeight{k};
        if isnumeric(item)
            height = height + item;
        elseif ischar(item) || isstring(item)
            if strcmpi(char(item), 'fit')
                height = height + defaultFitHeight;
            else
                height = height + defaultFlexHeight;
            end
        else
            height = height + defaultFitHeight;
        end
    end
    height = height + max(gridSize(1) - 1, 0) * rowSpacing;
end
