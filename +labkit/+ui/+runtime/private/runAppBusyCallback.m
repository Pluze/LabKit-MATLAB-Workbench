% Private Runtime V2 transaction helper. Expected caller: semantic callback
% dispatch. Inputs are the app figure, visible busy text, and one callback.
% Side effects: marks the figure busy and temporarily applies a working title
% and pointer without overwriting callback-owned changes during cleanup.
function runAppBusyCallback(fig, message, workFcn)
    validFig = isLiveFigure(fig);
    state = enterBusyState(fig, validFig, message);
    cleanupObj = onCleanup(@() restoreBusyState(state));
    drawnow;
    workFcn();
    clear cleanupObj
end

function state = enterBusyState(fig, validFig, message)
    state = struct( ...
        'fig', fig, ...
        'validFig', validFig, ...
        'oldName', "", ...
        'busyName', "", ...
        'oldPointer', "", ...
        'busyPointer', "watch", ...
        'busyState', struct('hadValue', false, 'value', []));
    if ~validFig
        return;
    end

    state.oldName = stripBusySuffix(fig.Name);
    text = strip(string(message));
    if strlength(text) == 0
        text = "Working";
    end
    state.busyName = state.oldName + " [Working: " + text + "]";
    fig.Name = char(state.busyName);

    if isprop(fig, 'Pointer')
        state.oldPointer = string(fig.Pointer);
        fig.Pointer = char(state.busyPointer);
    end
    state.busyState = setBusyFlag(fig, true);
end

function name = stripBusySuffix(name)
    name = string(name);
    while true
        stripped = string(regexprep(char(name), ...
            '\s*\[Working: [^\]]*\]\s*$', ''));
        if stripped == name
            return;
        end
        name = stripped;
    end
end

function previous = setBusyFlag(fig, value)
    key = 'labkitUiBusy';
    previous = struct('hadValue', isappdata(fig, key), 'value', []);
    if previous.hadValue
        previous.value = getappdata(fig, key);
    end
    setappdata(fig, key, logical(value));
end

function restoreBusyState(state)
    if ~state.validFig || ~isLiveFigure(state.fig)
        return;
    end
    fig = state.fig;
    key = 'labkitUiBusy';
    if state.busyState.hadValue
        setappdata(fig, key, state.busyState.value);
    elseif isappdata(fig, key)
        rmappdata(fig, key);
    end
    if isprop(fig, 'Pointer') && string(fig.Pointer) == state.busyPointer
        fig.Pointer = char(state.oldPointer);
    end
    if isprop(fig, 'Name') && string(fig.Name) == state.busyName
        fig.Name = char(state.oldName);
    end
    drawnow;
end

function tf = isLiveFigure(fig)
    tf = ~isempty(fig);
    if ~tf
        return;
    end
    try
        tf = all(isvalid(fig)) && isprop(fig, 'Name');
    catch
        tf = false;
    end
end
