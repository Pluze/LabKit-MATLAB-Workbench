% Private UI runtime helper. Expected callers: semantic callback wrappers under
% +labkit/+ui/+runtime/private. Inputs are a semantic control adapter, the
% originating MATLAB UI source/raw event, and a semantic source label. Output is
% the normalized event payload seen by app callbacks.
function event = semanticEvent(control, source, rawEvent, sourceKind)
    event = struct();
    event.id = control.id;
    event.kind = control.kind;
    event.source = sourceKind;
    event.value = currentValue(source);
    event.previousValue = previousValue(rawEvent);
    event.ui = currentUiRegistry(source);
    event.rawEvent = rawEvent;
end

function value = currentValue(source)
    if ~isempty(source) && isprop(source, 'Value')
        value = source.Value;
    else
        value = [];
    end
end

function value = previousValue(rawEvent)
    value = [];
    if ~isempty(rawEvent) && isprop(rawEvent, 'PreviousValue')
        value = rawEvent.PreviousValue;
    end
end

function ui = currentUiRegistry(source)
    fig = ancestor(source, 'figure');
    if isempty(fig) || ~isappdata(fig, 'labkitUiRegistry')
        error('labkit:ui:runtime:MissingRegistry', ...
            'UI registry appdata was not found on the current figure.');
    end
    ui = getappdata(fig, 'labkitUiRegistry');
end
