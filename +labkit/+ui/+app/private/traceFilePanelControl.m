% Private filePanel diagnostic helper. Expected caller: filePanel control
% builders and semantic callbacks. Inputs are a filePanel adapter plus event
% text. Side effects: emits a debug trace when debug mode is enabled.
function traceFilePanelControl(control, eventName, reason)
    if ~isstruct(control) || ~isfield(control, 'trace') || ...
            isempty(control.trace) || ~isa(control.trace, 'function_handle')
        return;
    end
    control.trace(control.panel, eventName, reason);
end
