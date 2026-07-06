function appendLog(ui, idOrMessage, maybeMessage)
%APPENDLOG Append a line to a UI 5 log panel.
%
% App-facing contract:
%   labkit.ui.control.appendLog(ui, message)
%   labkit.ui.control.appendLog(ui, id, message)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create.
%   id - optional logPanel id. If omitted, the first log panel is used.
%   message - text appended to the log panel.
%
% Output:
%   None.

    if nargin < 3
        id = firstControlOfKind(ui, 'logPanel');
        message = idOrMessage;
    else
        id = idOrMessage;
        message = maybeMessage;
    end

    control = resolveControl(ui, id);
    if ~isfield(control, 'textArea')
        error('labkit:ui:control:InvalidLogPanel', ...
            'Control "%s" is not a log panel.', control.id);
    end
    timestamp = datestr(now, 'HH:MM:SS');
    old = control.textArea.Value;
    old{end + 1} = sprintf('[%s] %s', timestamp, char(message));
    control.textArea.Value = old;
    if shouldFollowLatest(control.textArea)
        scrollLogToBottom(control.textArea);
    end
end

function tf = shouldFollowLatest(textArea)
    tf = true;
    try
        if isappdata(textArea, logFollowKey())
            tf = logical(getappdata(textArea, logFollowKey()));
        end
    catch
        tf = true;
    end
end

function scrollLogToBottom(textArea)
    try
        scroll(textArea, 'bottom');
    catch
    end
end

function key = logFollowKey()
    key = 'labkitLogFollowLatest';
end

function id = firstControlOfKind(ui, kind)
    names = fieldnames(ui.controls);
    for k = 1:numel(names)
        control = ui.controls.(names{k});
        if isfield(control, 'kind') && strcmp(control.kind, kind)
            id = names{k};
            return;
        end
    end
    error('labkit:ui:control:UnknownControl', ...
        'No UI control of kind "%s" exists.', kind);
end
