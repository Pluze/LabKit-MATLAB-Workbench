function debugLog = createAppDebugLog(appName, opts)
%CREATEAPPDEBUGLOG Create an app-neutral debug log sink.
%
% Usage:
%   debugLog = labkit.ui.createAppDebugLog("labkit_Example_app", opts);
%   debugLog.append("Loaded file");
%   lines = debugLog.getLog();
%
% Inputs:
%   appName - app entry-point name stored in debugLog.appName.
%   opts - optional struct with fields:
%       enabled - logical, default true. Disabled logs ignore appended text.
%       logFile - char/string filepath, default ''. When nonempty, appended
%           messages are also written to this text file.
%       logCallback - function handle, default []. Called as
%           logCallback(line) after each appended line.
%
% Output:
%   debugLog - struct with fields appName, enabled, logFile, append, getLog.
%       append is a function handle accepting one message. getLog returns the
%       captured cellstr lines. File and callback side effects happen only
%       when enabled is true.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    appName = string(appName);
    enabled = optionValue(opts, 'enabled', true);
    logFile = string(optionValue(opts, 'logFile', ""));
    logCallback = optionValue(opts, 'logCallback', []);
    lines = {};

    if enabled && strlength(logFile) > 0
        initializeLogFile(logFile, appName);
    end

    debugLog = struct();
    debugLog.appName = appName;
    debugLog.enabled = logical(enabled);
    debugLog.logFile = logFile;
    debugLog.append = @append;
    debugLog.getLog = @getLog;

    function append(message)
        if ~enabled
            return;
        end
        line = sprintf('[%s] %s', datestr(now, 'HH:MM:SS'), char(message));
        lines{end+1, 1} = line;
        if strlength(logFile) > 0
            appendLine(logFile, line);
        end
        if ~isempty(logCallback)
            logCallback(line);
        end
    end

    function out = getLog()
        out = lines;
    end
end

function initializeLogFile(logFile, appName)
    fid = fopen(logFile, 'w');
    if fid < 0
        error('labkit:ui:DebugLogFileOpenFailed', ...
            'Could not open debug log file: %s.', logFile);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, '%s debug log\n', char(appName));
end

function appendLine(logFile, line)
    fid = fopen(logFile, 'a');
    if fid < 0
        error('labkit:ui:DebugLogFileOpenFailed', ...
            'Could not open debug log file: %s.', logFile);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, '%s\n', char(line));
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
