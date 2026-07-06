% Private UI runtime helper. Expected caller: labkit.ui.runtime.create. Input is the
% app figure. Side effects: installs a close-request guard that confirms when
% the app is busy or marked dirty.
function installCloseGuard(fig)
    if ~isLiveFigure(fig)
        return;
    end

    previous = fig.CloseRequestFcn;
    setappdata(fig, 'labkitUiClosePreviousFcn', previous);
    fig.CloseRequestFcn = @(source, event) onCloseRequest(source, event);
end

function onCloseRequest(fig, event)
    if shouldConfirmClose(fig) && ~confirmClose(fig)
        return;
    end

    previous = [];
    if isLiveFigure(fig) && isappdata(fig, 'labkitUiClosePreviousFcn')
        previous = getappdata(fig, 'labkitUiClosePreviousFcn');
    end
    if ~isempty(previous)
        runPreviousCloseRequest(previous, fig, event);
    elseif isLiveFigure(fig)
        delete(fig);
    end
end

function tf = shouldConfirmClose(fig)
    tf = isBusy(fig) || isDirty(fig);
end

function tf = isBusy(fig)
    tf = false;
    try
        tf = isappdata(fig, 'labkitUiBusy') && logical(getappdata(fig, 'labkitUiBusy'));
    catch
        tf = false;
    end
end

function tf = isDirty(fig)
    tf = false;
    try
        tf = isappdata(fig, 'labkitUiCloseGuardDirty') && ...
            logical(getappdata(fig, 'labkitUiCloseGuardDirty'));
    catch
        tf = false;
    end
end

function tf = confirmClose(fig)
    message = closeMessage(fig);
    if isappdata(fig, 'labkitUiCloseConfirmFcn')
        tf = normalizeResponse(getappdata(fig, 'labkitUiCloseConfirmFcn'), ...
            fig, message);
        return;
    end

    try
        response = uiconfirm(fig, message, 'Close LabKit app?', ...
            'Options', {'Close', 'Cancel'}, ...
            'DefaultOption', 2, ...
            'CancelOption', 2);
        tf = strcmp(string(response), "Close");
    catch
        tf = false;
    end
end

function message = closeMessage(fig)
    if isBusy(fig)
        message = "LabKit is still working. Close anyway?";
        return;
    end
    message = "This app has unfinished work. Close anyway?";
    try
        if isappdata(fig, 'labkitUiCloseGuardMessage')
            message = string(getappdata(fig, 'labkitUiCloseGuardMessage'));
        end
    catch
    end
end

function tf = normalizeResponse(confirmFcn, fig, message)
    try
        response = confirmFcn(fig, message);
    catch
        tf = false;
        return;
    end
    if islogical(response)
        tf = isscalar(response) && response;
    else
        tf = any(strcmpi(string(response), ["close", "yes", "true", "ok"]));
    end
end

function runPreviousCloseRequest(previous, fig, event)
    if isa(previous, 'function_handle')
        previous(fig, event);
    elseif ischar(previous) || (isstring(previous) && isscalar(previous))
        eval(char(previous));
    elseif isLiveFigure(fig)
        delete(fig);
    end
end

function tf = isLiveFigure(fig)
    tf = ~isempty(fig);
    if ~tf
        return;
    end
    try
        tf = all(isvalid(fig)) && isprop(fig, 'CloseRequestFcn');
    catch
        tf = false;
    end
end
