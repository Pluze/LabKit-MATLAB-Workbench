function ui = createAppShell(spec)
%CREATEAPPSHELL Create the standard LabKit app shell from a named spec.
%
% Usage:
%   spec = struct('title', "Example", ...
%       'position', [90 70 1200 800], ...
%       'leftWidth', 360, ...
%       'options', struct('rightKind', 'dualPlot'));
%   ui = labkit.ui.createAppShell(spec);
%
% Inputs:
%   spec - struct with fields:
%       title - figure title text.
%       position - MATLAB figure position [x y width height].
%       leftWidth - initial left controls width in pixels.
%       options - optional app shell options.
%
% Output:
%   ui - struct of figure, layout, tab grids, and right-side handles.
%
% This is the app-facing shell entry point. Apps own controls and workflow
% inside the returned grids; the shell owns split-pane layout, tab host
% construction, scrollable tab grids, and standard right-pane plumbing.

    if nargin < 1 || ~isstruct(spec)
        error('labkit:ui:InvalidAppShellSpec', ...
            'createAppShell requires a scalar struct spec.');
    end
    required = {'title', 'position', 'leftWidth'};
    for k = 1:numel(required)
        if ~isfield(spec, required{k})
            error('labkit:ui:InvalidAppShellSpec', ...
                'App shell spec is missing "%s".', required{k});
        end
    end

    opts = optionValue(spec, 'options', struct());
    if isfield(spec, 'shellOptions')
        opts = spec.shellOptions;
    end
    ui = labkit.ui.createWorkbench(spec.title, spec.position, spec.leftWidth, opts);
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
