function ui = resultTable(parent, titleText, row, columnNames, initialData)
%CREATERESULTTABLEPANEL Create a titled result-table panel.
%
% Inputs:
%   parent - parent grid.
%   titleText - panel title.
%   row - logical parent row.
%   columnNames - cellstr/string column names.
%   initialData - optional initial table Data, default empty cell array.
%
% Output:
%   ui - struct with panel, grid, and table fields.

    if nargin < 5
        initialData = cell(0, numel(columnNames));
    end

    opts = struct('rowHeight', {{'1x'}}, 'columnWidth', {{'1x'}});
    ui = labkit.ui.view.section(parent, titleText, row, [1 1], opts);

    ui.table = uitable(ui.grid);
    ui.table.ColumnName = columnNames;
    ui.table.Data = initialData;
end
