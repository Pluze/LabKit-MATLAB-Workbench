function ui = createTabbedDualPlotShell(figName, figPosition, leftWidth, separatorButtonDownFcn, labels)
%CREATETABBEDDUALPLOTSHELL Create the shared tabbed dual-plot app shell.

    if nargin < 4
        separatorButtonDownFcn = [];
    end

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
    ui.separator.ButtonDownFcn = separatorButtonDownFcn;

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

    ui.filesAnalysisTab = uitab(ui.tabs, 'Title', labels.filesAnalysisTab);
    ui.filesAnalysisGrid = uigridlayout(ui.filesAnalysisTab, [3 1]);
    ui.filesAnalysisGrid.RowHeight = {260, 'fit', 'fit'};
    ui.filesAnalysisGrid.RowSpacing = 10;
    ui.filesAnalysisGrid.Padding = [8 8 8 8];

    ui.summaryResultsTab = uitab(ui.tabs, 'Title', labels.summaryResultsTab);
    ui.summaryResultsGrid = uigridlayout(ui.summaryResultsTab, [2 1]);
    ui.summaryResultsGrid.RowHeight = {'fit', '1x'};
    ui.summaryResultsGrid.RowSpacing = 10;
    ui.summaryResultsGrid.Padding = [8 8 8 8];

    ui.logTab = uitab(ui.tabs, 'Title', labels.logTab);
    ui.logGrid = uigridlayout(ui.logTab, [1 1]);
    ui.logGrid.RowHeight = {'1x'};
    ui.logGrid.Padding = [8 8 8 8];

    ui.rightPanel = uipanel(ui.main, 'Title', labels.plotsPanel);
    ui.rightPanel.Layout.Row = 1;
    ui.rightPanel.Layout.Column = 3;

    ui.rightGrid = uigridlayout(ui.rightPanel, [4 1]);
    ui.rightGrid.RowHeight = {'fit', '1x', 'fit', '1x'};
    ui.rightGrid.RowSpacing = 10;
    ui.rightGrid.Padding = [8 8 8 8];

    ui.topControlsPanel = uipanel(ui.rightGrid, 'Title', labels.topPlot);
    ui.topControlsPanel.Layout.Row = 1;

    ui.topAxes = uiaxes(ui.rightGrid);
    ui.topAxes.Layout.Row = 2;
    title(ui.topAxes, labels.topPlot);
    gamrywb.ui.disableAxesInteractivity(ui.topAxes);

    ui.bottomControlsPanel = uipanel(ui.rightGrid, 'Title', labels.bottomPlot);
    ui.bottomControlsPanel.Layout.Row = 3;

    ui.bottomAxes = uiaxes(ui.rightGrid);
    ui.bottomAxes.Layout.Row = 4;
    title(ui.bottomAxes, labels.bottomPlot);
    gamrywb.ui.disableAxesInteractivity(ui.bottomAxes);
end
