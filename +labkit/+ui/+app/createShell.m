function ui = createShell(spec)
%CREATESHELL Create the standard LabKit app shell from a named spec.
%
% Usage:
%   ui = labkit.ui.app.createShell(struct( ...
%       'title', "Example", ...
%       'position', [90 70 1200 800], ...
%       'leftWidth', 360, ...
%       'options', struct('rightKind', 'dualPlot')));
%
% Inputs:
%   spec - scalar struct with fields:
%       title - figure title text.
%       position - MATLAB figure position [x y width height].
%       leftWidth - initial left controls width in pixels.
%       options - optional shell options:
%           rightKind - "custom" or "dualPlot", default "custom".
%           rightGridSize - custom right grid size, default [1 1].
%           rightRowHeight - custom right grid rows, default {'1x'}.
%           rightRowSpacing - scalar spacing, default 8 or 10 for dualPlot.
%           showPlotControls - dualPlot only, default true.
%           controlsTitle, rightTitle, topPlotTitle, bottomPlotTitle - labels.
%           tabs - labkit.ui.app.tab struct array.
%
% Output:
%   ui - struct of figure, layout, tab grids, and right-side handles.
%
% Apps own controls and workflow inside the returned grids. The shell owns
% split-pane layout, tab construction, scrollable tab grids, resizable rows,
% and standard right-pane plumbing.

    if nargin < 1 || ~isstruct(spec) || ~isscalar(spec)
        error('labkit:ui:InvalidAppShellSpec', ...
            'createShell requires a scalar struct spec.');
    end
    required = {'title', 'position', 'leftWidth'};
    for k = 1:numel(required)
        if ~isfield(spec, required{k})
            error('labkit:ui:InvalidAppShellSpec', ...
                'App shell spec is missing "%s".', required{k});
        end
    end

    opts = optionValue(spec, 'options', struct());

    rightKind = char(string(optionValue(opts, 'rightKind', 'custom')));
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
        spec.title, spec.position, spec.leftWidth, shellLabels, tabSpecs, ...
        rightGridSize, rightRowHeight, rightRowSpacing);

    if strcmp(rightKind, 'dualPlot')
        ui = addDualPlotRegion(ui, opts);
    end
end

function tabs = standardTabs()
    tabs = [ ...
        labkit.ui.app.tab('filesAnalysis', 'Files + Analysis', [3 1], ...
            {260, 'fit', 'fit'}, ...
            struct('resizeRows', [1 2])), ...
        labkit.ui.app.tab('summaryResults', 'Summary + Results', [2 1], ...
            {'fit', '1x'}, ...
            struct('resizeRows', 1)), ...
        labkit.ui.app.tab('log', 'Log', [1 1], {'1x'})];
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
        labkit.ui.view.draw(ui.topAxes, 'popout');
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
        labkit.ui.view.draw(ui.topAxes, 'popout');
        disableAxesInteractivity(ui.topAxes);

        ui.bottomAxes = uiaxes(ui.rightGrid);
        ui.bottomAxes.Layout.Row = 2;
    end
    title(ui.bottomAxes, bottomTitle);
    labkit.ui.view.draw(ui.bottomAxes, 'popout');
    disableAxesInteractivity(ui.bottomAxes);
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
