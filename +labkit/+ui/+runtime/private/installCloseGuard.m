% Private UI runtime helper. Expected caller: labkit.ui.runtime.create. Input is the
% app figure. Side effects: installs a close-request guard that confirms before
% closing LabKit apps, with stronger wording when the app is busy.
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

    closeWithoutConfirm(fig, event);
end

function closeWithoutConfirm(fig, event)
    clearClosePrompt(fig);
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
    tf = isLiveFigure(fig);
end

function tf = isBusy(fig)
    tf = false;
    try
        tf = isappdata(fig, 'labkitUiBusy') && logical(getappdata(fig, 'labkitUiBusy'));
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

    if closePromptArmed(fig)
        tf = true;
        return;
    end

    showClosePrompt(fig, message);
    tf = false;
end

function message = closeMessage(fig)
    if isBusy(fig)
        message = "LabKit is still working. Close anyway?";
        return;
    end
    if isDirtyProject(fig)
        message = "This project has unsaved changes. Close anyway?";
        return;
    end
    message = "Close this LabKit app?";
end

function tf = isDirtyProject(fig)
    tf = false;
    if ~isappdata(fig, 'labkitUiAppRuntime')
        return;
    end
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    tf = isstruct(runtime) && isfield(runtime, 'document') && ...
        logical(runtime.document.dirty);
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

function showClosePrompt(fig, message)
    clearClosePrompt(fig);
    setappdata(fig, 'labkitUiClosePromptArmed', true);

    panel = uipanel(fig, ...
        'Title', 'Close LabKit app?', ...
        'Tag', 'labkitUiClosePrompt', ...
        'Position', promptPosition(fig));
    setappdata(fig, 'labkitUiClosePromptPanel', panel);

    grid = uigridlayout(panel, [2 3]);
    grid.RowHeight = {'1x', 34};
    grid.ColumnWidth = {'1x', 86, 86};
    grid.Padding = [10 8 10 8];
    grid.RowSpacing = 6;
    grid.ColumnSpacing = 8;

    label = uilabel(grid, ...
        'Text', char(string(message) + " Close again to confirm."), ...
        'WordWrap', 'on', ...
        'FontWeight', 'bold');
    label.Layout.Row = 1;
    label.Layout.Column = [1 3];

    closeButton = uibutton(grid, ...
        'Text', 'Close', ...
        'ButtonPushedFcn', @(~, event) closeWithoutConfirm(fig, event));
    closeButton.Layout.Row = 2;
    closeButton.Layout.Column = 2;

    cancelButton = uibutton(grid, ...
        'Text', 'Cancel', ...
        'ButtonPushedFcn', @(~, ~) clearClosePrompt(fig));
    cancelButton.Layout.Row = 2;
    cancelButton.Layout.Column = 3;
    drawnow;
end

function tf = closePromptArmed(fig)
    tf = false;
    try
        tf = isLiveFigure(fig) && isappdata(fig, 'labkitUiClosePromptArmed') && ...
            logical(getappdata(fig, 'labkitUiClosePromptArmed'));
    catch
        tf = false;
    end
end

function clearClosePrompt(fig)
    if ~isLiveFigure(fig)
        return;
    end
    if isappdata(fig, 'labkitUiClosePromptArmed')
        rmappdata(fig, 'labkitUiClosePromptArmed');
    end
    if isappdata(fig, 'labkitUiClosePromptPanel')
        panel = getappdata(fig, 'labkitUiClosePromptPanel');
        if isvalid(panel)
            delete(panel);
        end
        rmappdata(fig, 'labkitUiClosePromptPanel');
    end
end

function pos = promptPosition(fig)
    width = 430;
    height = 118;
    figPos = fig.Position;
    promptWidth = min(width, max(160, figPos(3) - 24));
    x = max(12, (figPos(3) - promptWidth) / 2);
    y = max(12, figPos(4) - height - 44);
    pos = [x y promptWidth height];
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
