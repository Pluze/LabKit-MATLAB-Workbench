function ui = create(spec, varargin)
%CREATE Build a LabKit UI 3.0 workbench from declarative specs.
%
% App-facing contract:
%   ui = labkit.ui.app.create(spec, "debug", debugContext)
%
% Inputs:
%   spec - scalar app spec from labkit.ui.spec.app. The app spec owns
%       controlTabs and workspace specs; all controls use globally unique ids.
%   debug - optional labkit.ui.diag debug context. When supplied, the created
%       figure is instrumented and the first logPanel mirrors trace lines.
%
% Output:
%   ui - registry struct with figure/fig, shell handles, controls, sections,
%       tabs, workspace, original spec, and optional debug context. Stable app
%       code should use semantic ids and named labkit.ui.view helpers rather
%       than adapter internals.

    opts = parseOptions(varargin);
    validateAppSpec(spec);

    debug = optionValue(opts, 'debug', []);
    ui = buildShellFromSpec(spec, debug);
    startupLifecycle(ui.figure, 'start', ui, "Building controls...");
    installCloseGuard(ui.figure);
    ui = buildControlTabs(ui, spec.props.controlTabs, debug);
    startupLifecycle(ui.figure, 'update', "Preparing workspace...");
    ui = buildWorkspace(ui, spec.props.workspace, debug);
    startupLifecycle(ui.figure, 'update', "Preparing app...");

    if isDebugEnabled(debug) && isfield(debug, 'instrumentFigure')
        debug.instrumentFigure(ui.figure);
    end
    setappdata(ui.figure, 'labkitUiRegistry', ui);
    setappdata(ui.figure, 'labkitUiDebugContext', debug);
    startupLifecycle(ui.figure, 'finish', "Ready.");
end

function opts = parseOptions(args)
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:app:InvalidOptions', ...
            'labkit.ui.app.create options must be name/value pairs.');
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

function tf = isDebugEnabled(debugContext)
    tf = isstruct(debugContext) && isfield(debugContext, 'enabled') && ...
        logical(debugContext.enabled);
end
