function ui = createResultTablePanel(parent, titleText, row, columnNames, initialData)
%CREATERESULTTABLEPANEL Create a titled result-table panel.

    if nargin < 5
        initialData = cell(0, numel(columnNames));
    end

    ui = struct();
    ui.panel = uipanel(parent, 'Title', titleText);
    ui.panel.Layout.Row = row;

    ui.grid = uigridlayout(ui.panel, [1 1]);
    ui.grid.Padding = [8 8 8 8];

    ui.table = uitable(ui.grid);
    ui.table.ColumnName = columnNames;
    ui.table.Data = initialData;
end
