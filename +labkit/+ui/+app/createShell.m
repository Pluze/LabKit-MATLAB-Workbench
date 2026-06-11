function ui = createShell(spec)
%CREATESHELL Create the standard LabKit app shell from a named spec.
%
% Usage:
%   ui = labkit.ui.app.createShell(struct( ...
%       'title', "Example", ...
%       'position', [90 70 1200 800], ...
%       'leftWidth', 360, ...
%       'options', struct('rightGridSize', [1 1])));
%
% Inputs:
%   spec - scalar struct with fields:
%       title - figure title text.
%       position - MATLAB figure position [x y width height].
%       leftWidth - initial left controls width in pixels.
%       options - optional shell options:
%           rightGridSize - custom right grid size, default [1 1].
%           rightRowHeight - custom right grid rows, default {'1x'}.
%           rightRowSpacing - scalar right-grid spacing, default 8.
%           rightTitle - right panel label.
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

    rightGridSize = optionValue(opts, 'rightGridSize', [1 1]);
    rightRowHeight = optionValue(opts, 'rightRowHeight', {'1x'});
    rightRowSpacing = optionValue(opts, 'rightRowSpacing', 8);

    shellLabels = struct( ...
        'controlsPanel', 'Controls', ...
        'rightPanel', optionValue(opts, 'rightTitle', 'Plots'));
    tabSpecs = optionValue(opts, 'tabs', standardTabs());

    ui = createTabbedWorkbenchShell( ...
        spec.title, spec.position, spec.leftWidth, shellLabels, tabSpecs, ...
        rightGridSize, rightRowHeight, rightRowSpacing);
end

function tabs = standardTabs()
    tabs = [ ...
        labkit.ui.app.tab('filesAnalysis', 'Files + Analysis', [3 1], ...
            {260, 'fit', 'fit'}), ...
        labkit.ui.app.tab('summaryResults', 'Summary + Results', [2 1], ...
            {'fit', '1x'}), ...
        labkit.ui.app.tab('log', 'Log', [1 1], {'1x'})];
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
