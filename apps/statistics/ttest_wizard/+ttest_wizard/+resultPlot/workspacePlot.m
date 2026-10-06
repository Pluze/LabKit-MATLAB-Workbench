function plotNode = workspacePlot()
%WORKSPACEPLOT Build the comparison-plot workspace node and renderer link.
%
% Expected caller: workbench.buildLayout.

plotNode = labkit.app.layout.plotArea( ...
    "resultPlot", @ttest_wizard.resultPlot.drawComparison, ...
    Title="Statistical comparison plot", ...
    AxisIds="main", AxisTitles="");
end
