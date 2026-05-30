function ui = createPanelGrid(parent, titleText, row, gridSize, opts)
%CREATEPANELGRID Create a standard titled panel containing a grid layout.

    if nargin < 5
        opts = struct();
    end

    ui = struct();
    ui.panel = uipanel(parent, 'Title', titleText);
    if nargin >= 3 && ~isempty(row)
        ui.panel.Layout.Row = row;
    end

    ui.grid = uigridlayout(ui.panel, gridSize);
    ui.grid.RowHeight = optionValue(opts, 'rowHeight', defaultRowHeight(gridSize));
    ui.grid.ColumnWidth = optionValue(opts, 'columnWidth', defaultColumnWidth(gridSize));
    ui.grid.Padding = optionValue(opts, 'padding', [8 8 8 8]);
    ui.grid.RowSpacing = optionValue(opts, 'rowSpacing', 8);
    ui.grid.ColumnSpacing = optionValue(opts, 'columnSpacing', 8);
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
