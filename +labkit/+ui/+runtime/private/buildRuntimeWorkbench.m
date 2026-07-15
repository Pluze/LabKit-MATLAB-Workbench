% Private UI runtime helper. Expected callers are labkit.ui.runtime.create and
% runV2App. Inputs are one declarative workbench layout and an optional debug
% context. Output is the fully constructed UI registry with startup readiness
% still active. Side effects create and instrument the app figure; the caller
% must finish startup only after its own initial presentation is ready.
function ui = buildRuntimeWorkbench(layout, debug, progressReporter)
    if nargin < 3
        progressReporter = [];
    end
    validateWorkbenchLayout(layout);
    ui = buildShellFromLayout(layout, debug);
    startupLifecycle(ui.figure, 'start', ui, "Building controls...", ...
        progressReporter);
    installCloseGuard(ui.figure);
    ui = buildControlTabs(ui, layout.props.controlTabs, debug);
    startupLifecycle(ui.figure, 'update', "Preparing workspace...");
    ui = buildWorkspace(ui, layout.props.workspace, debug);
    startupLifecycle(ui.figure, 'update', "Preparing runtime...");

    if isDebugEnabled(debug) && isfield(debug, 'instrumentFigure')
        debug.instrumentFigure(ui.figure);
    end
    setappdata(ui.figure, 'labkitUiRegistry', ui);
    setappdata(ui.figure, 'labkitUiDebugContext', debug);
end

function tf = isDebugEnabled(debugContext)
    tf = isstruct(debugContext) && isfield(debugContext, 'enabled') && ...
        logical(debugContext.enabled);
end
