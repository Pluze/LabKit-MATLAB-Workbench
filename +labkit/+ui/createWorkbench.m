function ui = createWorkbench(figName, figPosition, leftWidth, opts)
%CREATEWORKBENCH Create the standard resizable tabbed scientific-app shell.

    if nargin < 4
        opts = struct();
    end

    rightKind = optionValue(opts, 'rightKind', 'custom');
    rightGridSize = optionValue(opts, 'rightGridSize', [1 1]);
    rightRowHeight = optionValue(opts, 'rightRowHeight', {'1x'});
    rightRowSpacing = optionValue(opts, 'rightRowSpacing', 8);
    if strcmp(rightKind, 'dualPlot')
        showPlotControls = optionValue(opts, 'showPlotControls', true);
        if showPlotControls
            rightGridSize = [4 1];
            rightRowHeight = {'fit', '1x', 'fit', '1x'};
        else
            rightGridSize = [2 1];
            rightRowHeight = {'1x', '1x'};
        end
        rightRowSpacing = optionValue(opts, 'rightRowSpacing', 10);
    end

    shellLabels = struct( ...
        'controlsPanel', optionValue(opts, 'controlsTitle', 'Controls'), ...
        'rightPanel', optionValue(opts, 'rightTitle', 'Plots'));
    tabSpecs = optionValue(opts, 'tabs', standardTabs());

    ui = createTabbedWorkbenchShell( ...
        figName, figPosition, leftWidth, shellLabels, tabSpecs, ...
        rightGridSize, rightRowHeight, rightRowSpacing);

    if strcmp(rightKind, 'dualPlot')
        ui = addDualPlotRegion(ui, opts);
    end
end

function tabs = standardTabs()
    tabs = [ ...
        labkit.ui.tabSpec('filesAnalysis', 'Files + Analysis', [3 1], {260, 'fit', 'fit'}), ...
        labkit.ui.tabSpec('summaryResults', 'Summary + Results', [2 1], {'fit', '1x'}), ...
        labkit.ui.tabSpec('log', 'Log', [1 1], {'1x'})];
end

function ui = addDualPlotRegion(ui, opts)
    topTitle = optionValue(opts, 'topPlotTitle', 'Top Plot');
    bottomTitle = optionValue(opts, 'bottomPlotTitle', 'Bottom Plot');
    showPlotControls = optionValue(opts, 'showPlotControls', true);

    if showPlotControls
        ui.topControlsPanel = uipanel(ui.rightGrid, 'Title', topTitle);
        ui.topControlsPanel.Layout.Row = 1;

        ui.topAxes = uiaxes(ui.rightGrid);
        ui.topAxes.Layout.Row = 2;
        title(ui.topAxes, topTitle);
        disableAxesInteractivity(ui.topAxes);

        ui.bottomControlsPanel = uipanel(ui.rightGrid, 'Title', bottomTitle);
        ui.bottomControlsPanel.Layout.Row = 3;

        ui.bottomAxes = uiaxes(ui.rightGrid);
        ui.bottomAxes.Layout.Row = 4;
    else
        ui.topControlsPanel = [];
        ui.bottomControlsPanel = [];

        ui.topAxes = uiaxes(ui.rightGrid);
        ui.topAxes.Layout.Row = 1;
        title(ui.topAxes, topTitle);
        disableAxesInteractivity(ui.topAxes);

        ui.bottomAxes = uiaxes(ui.rightGrid);
        ui.bottomAxes.Layout.Row = 2;
    end
    title(ui.bottomAxes, bottomTitle);
    disableAxesInteractivity(ui.bottomAxes);
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
