function ui = createTabbedDualPlotShell(figName, figPosition, leftWidth, labels)
%CREATETABBEDDUALPLOTSHELL Create the shared tabbed dual-plot app shell.
%
% Inputs:
%   figName, figPosition, leftWidth - forwarded to createWorkbench.
%   labels - optional struct with controlsPanel, plotsPanel, topPlot,
%            and bottomPlot fields. Missing fields use defaults.
%
% Output:
%   ui - workbench struct with dual-plot handles.
%
% Calling guidance:
%   Prefer createWorkbench(..., struct('rightKind','dualPlot')) for new apps.

    if nargin < 4 || isempty(labels)
        labels = defaultLabels();
    else
        labels = mergeLabels(defaultLabels(), labels);
    end

    opts = struct();
    opts.rightKind = 'dualPlot';
    opts.controlsTitle = labels.controlsPanel;
    opts.rightTitle = labels.plotsPanel;
    opts.topPlotTitle = labels.topPlot;
    opts.bottomPlotTitle = labels.bottomPlot;
    ui = labkit.ui.createWorkbench(figName, figPosition, leftWidth, opts);
end

function labels = mergeLabels(defaults, overrides)
    labels = defaults;
    fields = fieldnames(overrides);
    for k = 1:numel(fields)
        labels.(fields{k}) = overrides.(fields{k});
    end
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
