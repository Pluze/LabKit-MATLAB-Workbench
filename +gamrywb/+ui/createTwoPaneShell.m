function ui = createTwoPaneShell(figName, figPosition, leftWidth, rightTitle, rightGridSize, rightRowHeight, rightRowSpacing)
%CREATETWOPANESHELL Create the shared two-pane app shell.

    ui = struct();
    ui.fig = uifigure( ...
        'Name', figName, ...
        'Position', figPosition);

    ui.main = uigridlayout(ui.fig, [1 2]);
    ui.main.ColumnWidth = {leftWidth, '1x'};
    ui.main.RowHeight = {'1x'};
    ui.main.Padding = [10 10 10 10];
    ui.main.ColumnSpacing = 10;

    ui.leftPanel = uipanel(ui.main, 'Title', 'Controls');
    ui.leftPanel.Layout.Row = 1;
    ui.leftPanel.Layout.Column = 1;

    ui.leftGrid = uigridlayout(ui.leftPanel, [5 1]);
    ui.leftGrid.RowHeight = {'fit', '1x', 'fit', 'fit', '1x'};
    ui.leftGrid.ColumnWidth = {'1x'};
    ui.leftGrid.Padding = [8 8 8 8];
    ui.leftGrid.RowSpacing = 10;

    ui.rightPanel = uipanel(ui.main, 'Title', rightTitle);
    ui.rightPanel.Layout.Row = 1;
    ui.rightPanel.Layout.Column = 2;

    ui.rightGrid = uigridlayout(ui.rightPanel, rightGridSize);
    ui.rightGrid.RowHeight = rightRowHeight;
    ui.rightGrid.ColumnWidth = {'1x'};
    ui.rightGrid.Padding = [8 8 8 8];
    ui.rightGrid.RowSpacing = rightRowSpacing;
end
