function ui = createTabbedDualPlotShell(figName, figPosition, leftWidth, labels)
%CREATETABBEDDUALPLOTSHELL Create the shared tabbed dual-plot app shell.

    shellLabels = struct( ...
        'controlsPanel', labels.controlsPanel, ...
        'rightPanel', labels.plotsPanel);
    tabSpecs = [ ...
        tabSpec('filesAnalysis', labels.filesAnalysisTab, [3 1], {260, 'fit', 'fit'}), ...
        tabSpec('summaryResults', labels.summaryResultsTab, [2 1], {'fit', '1x'}), ...
        tabSpec('log', labels.logTab, [1 1], {'1x'})];

    ui = labkit.ui.createTabbedWorkbenchShell( ...
        figName, figPosition, leftWidth, shellLabels, tabSpecs, ...
        [4 1], {'fit', '1x', 'fit', '1x'}, 10);

    ui.topControlsPanel = uipanel(ui.rightGrid, 'Title', labels.topPlot);
    ui.topControlsPanel.Layout.Row = 1;

    ui.topAxes = uiaxes(ui.rightGrid);
    ui.topAxes.Layout.Row = 2;
    title(ui.topAxes, labels.topPlot);
    labkit.ui.disableAxesInteractivity(ui.topAxes);

    ui.bottomControlsPanel = uipanel(ui.rightGrid, 'Title', labels.bottomPlot);
    ui.bottomControlsPanel.Layout.Row = 3;

    ui.bottomAxes = uiaxes(ui.rightGrid);
    ui.bottomAxes.Layout.Row = 4;
    title(ui.bottomAxes, labels.bottomPlot);
    labkit.ui.disableAxesInteractivity(ui.bottomAxes);
end

function spec = tabSpec(key, titleText, gridSize, rowHeight)
    spec = struct( ...
        'key', key, ...
        'title', titleText, ...
        'gridSize', gridSize, ...
        'rowHeight', {rowHeight}, ...
        'columnWidth', {{'1x'}});
end
