function setCloseGuard(fig, dirty, message)
%SETCLOSEGUARD Mark whether a LabKit app should confirm before closing.
%
% App-facing contract:
%   labkit.ui.app.setCloseGuard(fig, dirty)
%   labkit.ui.app.setCloseGuard(fig, dirty, message)
%
% Inputs:
%   fig - app figure created by labkit.ui.app.create.
%   dirty - true when closing should ask the user to confirm.
%   message - optional confirmation message for dirty workflow state. Busy
%       work uses the framework busy-state message instead.
%
% Outputs: none.
%
% Side effects:
%   Stores close-guard state on the figure. Invalid or deleted figures are
%   ignored so apps can call this during refresh paths without defensive code.

    if nargin < 2
        dirty = false;
    end
    if nargin < 3 || strlength(strtrim(string(message))) == 0
        message = "This app has unfinished work. Close anyway?";
    end
    if ~isLiveFigure(fig)
        return;
    end

    setappdata(fig, 'labkitUiCloseGuardDirty', logical(dirty));
    setappdata(fig, 'labkitUiCloseGuardMessage', char(string(message)));
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
