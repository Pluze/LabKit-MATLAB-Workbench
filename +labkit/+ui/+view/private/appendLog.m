% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function appendLog(txtLog, msg)
%APPENDLOG Append a timestamped line to a text-area style log control.
%
% Inputs:
%   txtLog - uitextarea-compatible handle with a cellstr Value.
%   msg - char/string message to append.
%
% Output:
%   Mutates txtLog.Value in place; no return value.

    timestamp = datestr(now, 'HH:MM:SS');
    old = txtLog.Value;
    old{end+1} = sprintf('[%s] %s', timestamp, char(msg));
    txtLog.Value = old;
    drawnow limitrate
end
