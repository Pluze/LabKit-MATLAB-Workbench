function ui = createTabbedDualPlotShell(figName, figPosition, leftWidth, labels)
%CREATETABBEDDUALPLOTSHELL Create the shared tabbed dual-plot app shell.

    if nargin < 4 || isempty(labels)
        labels = defaultLabels();
    end

    opts = struct();
    opts.rightKind = 'dualPlot';
    opts.controlsTitle = labels.controlsPanel;
    opts.rightTitle = labels.plotsPanel;
    opts.topPlotTitle = labels.topPlot;
    opts.bottomPlotTitle = labels.bottomPlot;
    ui = labkit.ui.createWorkbench(figName, figPosition, leftWidth, opts);
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
