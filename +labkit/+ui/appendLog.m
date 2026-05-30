function appendLog(txtLog, msg)
%APPENDLOG Append a timestamped line to a text-area style log control.

    timestamp = datestr(now, 'HH:MM:SS');
    old = txtLog.Value;
    old{end+1} = sprintf('[%s] %s', timestamp, char(msg));
    txtLog.Value = old;
    drawnow limitrate
end
