function ui = create(layout, varargin)
%CREATE Build a LabKit workbench from a declarative layout.
%
% App-facing contract:
%   ui = labkit.ui.runtime.create(layout, "debug", debugContext)
%
% Inputs:
%   layout - scalar layout tree from labkit.ui.layout.workbench. The layout owns
%       controlTabs and workspace children; all controls use globally unique ids.
%   debug - optional labkit.ui.debug context. When supplied, the created
%       figure is instrumented and the first logPanel mirrors trace lines.
%
% Output:
%   ui - registry struct with figure/fig, shell handles, controls, sections,
%       tabs, workspace, original layout, and optional debug context. Stable app
%       framework code should use semantic ids and runtime-private control or
%       labkit.ui.plot helpers rather than adapter internals.

    opts = parseOptions(varargin);
    debug = optionValue(opts, 'debug', []);
    ui = buildRuntimeWorkbench(layout, debug, ...
        startupProgressReporter(struct()));
    startupLifecycle(ui.figure, 'finish', "Ready.");
end

function opts = parseOptions(args)
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:runtime:InvalidOptions', ...
            'labkit.ui.runtime.create options must be name/value pairs.');
    end
    opts = struct();
    for k = 1:2:numel(args)
        opts.(char(string(args{k}))) = args{k + 1};
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
