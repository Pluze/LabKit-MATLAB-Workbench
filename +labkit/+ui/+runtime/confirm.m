function confirmed = confirm(fig, message, titleText, varargin)
%CONFIRM Ask a two-choice app confirmation with hidden-test support.
%
% App-facing contract:
%   confirmed = labkit.ui.runtime.confirm(fig, message, titleText)
%   confirmed = labkit.ui.runtime.confirm(..., ...
%       "ConfirmText", "Restore", "CancelText", "Start new")
%
% Inputs:
%   fig - owning app uifigure.
%   message - user-facing question.
%   titleText - dialog title.
%   ConfirmText - optional affirmative label, default Continue.
%   CancelText - optional negative label, default Cancel.
%
% Output:
%   confirmed - true only when the affirmative choice is selected. Hidden GUI
%       mode returns false unless a labkitUiConfirmFcn test hook is installed
%       as appdata on fig.

    opts = parseOptions(varargin);
    confirmText = string(opts.ConfirmText);
    cancelText = string(opts.CancelText);
    recordConfirmation(fig, message, titleText, confirmText, cancelText);
    if isappdata(fig, 'labkitUiConfirmFcn')
        confirmed = injectedResponse(getappdata(fig, 'labkitUiConfirmFcn'), ...
            fig, message, titleText, confirmText, cancelText);
        return;
    end
    if string(getenv('LABKIT_GUI_TEST_MODE')) == "hidden"
        confirmed = false;
        return;
    end
    answer = uiconfirm(fig, message, titleText, ...
        'Options', {char(confirmText), char(cancelText)}, ...
        'DefaultOption', 2, 'CancelOption', 2);
    confirmed = string(answer) == confirmText;
end

function opts = parseOptions(args)
    p = inputParser;
    p.FunctionName = 'labkit.ui.runtime.confirm';
    p.addParameter('ConfirmText', 'Continue', @(x) ischar(x) || isstring(x));
    p.addParameter('CancelText', 'Cancel', @(x) ischar(x) || isstring(x));
    p.parse(args{:});
    opts = p.Results;
end

function confirmed = injectedResponse(callback, fig, message, titleText, confirmText, cancelText)
    try
        response = callback(fig, message, titleText, confirmText, cancelText);
    catch
        confirmed = false;
        return;
    end
    if islogical(response)
        confirmed = isscalar(response) && response;
    else
        confirmed = any(strcmpi(string(response), [confirmText, "yes", "true", "ok"]));
    end
end

function recordConfirmation(fig, message, titleText, confirmText, cancelText)
    record = struct('title', string(titleText), 'message', string(message), ...
        'confirmText', confirmText, 'cancelText', cancelText);
    if isappdata(fig, 'labkitUiConfirmations')
        records = getappdata(fig, 'labkitUiConfirmations');
        records(end + 1, 1) = record;
    else
        records = record;
    end
    setappdata(fig, 'labkitUiConfirmations', records);
end
