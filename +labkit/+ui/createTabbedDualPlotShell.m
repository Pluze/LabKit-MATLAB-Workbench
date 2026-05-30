function ui = createTabbedDualPlotShell(figName, figPosition, leftWidth, labels)
%CREATETABBEDDUALPLOTSHELL Create the shared tabbed dual-plot app shell.

    if nargin < 4 || isempty(labels)
        labels = defaultLabels();
    end

    ui = labkit.ui.createStandardWorkbenchShell( ...
        figName, figPosition, leftWidth, labels.plotsPanel, ...
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

function labels = defaultLabels()
    labels = struct( ...
        'controlsPanel', 'Controls', ...
        'filesAnalysisTab', 'Files + Analysis', ...
        'summaryResultsTab', 'Summary + Results', ...
        'logTab', 'Log', ...
        'plotsPanel', 'Plots', ...
        'topPlot', 'Top Plot', ...
        'bottomPlot', 'Bottom Plot');
end
