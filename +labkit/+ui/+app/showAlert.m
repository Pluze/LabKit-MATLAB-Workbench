function shown = showAlert(fig, message, titleText)
%SHOWALERT Show an app alert, or record it during hidden GUI tests.
%
% App-facing contract:
%   shown = labkit.ui.app.showAlert(fig, message, titleText)
%
% Inputs:
%   fig - app uifigure that owns the alert.
%   message - user-facing alert message owned by the calling app.
%   titleText - user-facing alert title owned by the calling app.
%
% Output:
%   shown - true when a modal alert was shown, false when hidden GUI test
%       mode recorded the alert without opening a modal dialog.

    if nargin < 3
        titleText = "";
    end
    recordAlert(fig, message, titleText);
    if isHiddenGuiTestMode()
        traceAlert(fig, message, titleText, "skipped-hidden-gui");
        shown = false;
        return;
    end
    traceAlert(fig, message, titleText, "shown");
    uialert(fig, message, titleText);
    shown = true;
end

function tf = isHiddenGuiTestMode()
    tf = string(getenv('LABKIT_GUI_TEST_MODE')) == "hidden";
end

function recordAlert(fig, message, titleText)
    if isempty(fig) || ~isvalid(fig)
        return;
    end
    alert = struct( ...
        'title', string(titleText), ...
        'message', string(message));
    if isappdata(fig, 'labkitUiAlerts')
        alerts = getappdata(fig, 'labkitUiAlerts');
        alerts(end + 1, 1) = alert;
    else
        alerts = alert;
    end
    setappdata(fig, 'labkitUiAlerts', alerts);
end

function traceAlert(fig, message, titleText, reason)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, 'labkitUiDebugContext')
        return;
    end
    debug = getappdata(fig, 'labkitUiDebugContext');
    if isstruct(debug) && isfield(debug, 'trace') && isa(debug.trace, 'function_handle')
        debug.trace('alert', sprintf('%s: %s', char(string(titleText)), ...
            char(string(message))), reason);
    end
end
