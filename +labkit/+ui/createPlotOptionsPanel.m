function ui = createPlotOptionsPanel(parent, rowCount, row)
%CREATEPLOTOPTIONSPANEL Create the shared plot-options panel grid.

    if nargin < 3 || isempty(row)
        row = 3;
    end

    ui = struct();
    ui.panel = uipanel(parent, 'Title', 'Plot Options');
    ui.panel.Layout.Row = row;

    ui.grid = uigridlayout(ui.panel, [rowCount 2]);
    ui.grid.RowHeight = repmat({'fit'}, 1, rowCount);
    ui.grid.ColumnWidth = {'fit', '1x'};
    ui.grid.Padding = [8 8 8 8];
    ui.grid.RowSpacing = 8;
    ui.grid.ColumnSpacing = 8;
end
