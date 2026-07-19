function plotNode = workspacePlot()
%WORKSPACEPLOT Build the comparison-plot workspace node and renderer link.
%
% Expected caller: workbench.buildLayout.

plotNode = labkit.app.layout.plotArea( ...
    "resultPlot", @ttest_wizard.resultPlot.drawComparison, ...
    AxisIds="main");
end
