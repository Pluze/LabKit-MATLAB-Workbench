% Private filePanel diagnostic helper. Expected caller: semantic filePanel
% callback wiring. Inputs are the filePanel id, MATLAB source handle, event
% text, and reason. Side effects: emits a debug trace through the UI registry.
function traceFilePanelFromSource(id, source, eventName, reason)
    ui = currentUiRegistry(source);
    if ~isfield(ui, 'debug') || ~isstruct(ui.debug) || ...
            ~isfield(ui.debug, 'trace') || ~isa(ui.debug.trace, 'function_handle')
        return;
    end
    ui.debug.trace('filePanel', sprintf('%s %s', char(string(id)), eventName), reason);
end

function ui = currentUiRegistry(source)
    fig = ancestor(source, 'figure');
    if isempty(fig) || ~isappdata(fig, 'labkitUiRegistry')
        error('labkit:ui:app:MissingRegistry', ...
            'UI registry appdata was not found on the current figure.');
    end
    ui = getappdata(fig, 'labkitUiRegistry');
end
