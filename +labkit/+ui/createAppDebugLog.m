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
%       traceEnabled - logical, default same as enabled. Disabled trace logs
%           ignore trace and callback wrapper messages while preserving append.
%       logFile - char/string filepath, default ''. When nonempty, appended
%           and trace messages are also written to this text file.
%       logCallback - function handle, default []. Called as
%           logCallback(line) after each appended line.
%       traceCallback - function handle, default []. Called as
%           traceCallback(line) after each trace line.
%
% Output:
%   debugLog - struct with fields appName, enabled, traceEnabled, logFile,
%       append, trace, setTraceCallback, attachTextLog, wrapCallback,
%       instrumentFigure, and getLog. append records app-level messages.
%       trace records verbose debug messages only when traceEnabled is true.
%       setTraceCallback(fcn) changes the trace-only mirror callback after the
%       app has created its visible log control. attachTextLog(textArea)
%       mirrors trace lines into a LabKit log text area. wrapCallback(name,
%       fcn) returns a callback wrapper that logs BEGIN/END/ERROR trace
%       messages around fcn. instrumentFigure(fig) wraps common component
%       callbacks on existing figure children; instrumentFigure(fig, opts)
%       accepts opts.callbackProperties as a string/cellstr list of callback
%       property names. Trace messages include the control label plus callback
%       function name where MATLAB exposes it. Low-level pointer, drag, and
%       scroll callbacks are omitted by default but may be supplied through
%       opts.callbackProperties when needed. getLog returns captured cellstr
%       lines. File and callback side effects happen only when enabled is true.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    appName = string(appName);
    enabled = optionValue(opts, 'enabled', true);
    traceEnabled = optionValue(opts, 'traceEnabled', enabled);
    logFile = string(optionValue(opts, 'logFile', ""));
    logCallback = optionValue(opts, 'logCallback', []);
    traceCallback = optionValue(opts, 'traceCallback', []);
    lines = {};

    if enabled && strlength(logFile) > 0
        initializeLogFile(logFile, appName);
    end

    debugLog = struct();
    debugLog.appName = appName;
    debugLog.enabled = logical(enabled);
    debugLog.traceEnabled = logical(traceEnabled);
    debugLog.logFile = logFile;
    debugLog.append = @append;
    debugLog.trace = @trace;
    debugLog.setTraceCallback = @setTraceCallback;
    debugLog.attachTextLog = @attachTextLog;
    debugLog.wrapCallback = @wrapCallback;
    debugLog.instrumentFigure = @instrumentFigure;
    debugLog.getLog = @getLog;

    function append(message)
        if ~enabled
            return;
        end
        appendLineValue(char(message));
    end

    function trace(message)
        if ~enabled || ~traceEnabled
            return;
        end
        line = appendLineValue(sprintf('[debug] %s', char(message)));
        if ~isempty(traceCallback)
            traceCallback(line);
        end
    end

    function setTraceCallback(callback)
        traceCallback = callback;
    end

    function attachTextLog(textArea)
        setTraceCallback(@appendTraceToTextLog);

        function appendTraceToTextLog(line)
            if isempty(textArea) || ~isvalid(textArea)
                return;
            end
            labkit.ui.appendLog(textArea, line);
        end
    end

    function wrappedCallback = wrapCallback(name, callback)
        if isempty(callback)
            wrappedCallback = [];
            return;
        end

        callbackName = char(string(name));
        originalCallback = callback;
        wrappedCallback = @wrapped;

        function varargout = wrapped(varargin)
            trace(sprintf('BEGIN %s', callbackName));
            try
                if nargout == 0
                    originalCallback(varargin{:});
                    trace(sprintf('END %s', callbackName));
                else
                    [varargout{1:nargout}] = originalCallback(varargin{:});
                    trace(sprintf('END %s', callbackName));
                end
            catch ME
                trace(sprintf('ERROR %s: %s %s', ...
                    callbackName, ME.identifier, ME.message));
                rethrow(ME);
            end
        end
    end

    function count = instrumentFigure(fig, opts)
        if nargin < 2
            opts = struct();
        end
        count = 0;
        if ~enabled || ~traceEnabled || isempty(fig) || ~isvalid(fig)
            return;
        end

        callbackProps = optionValue(opts, 'callbackProperties', defaultCallbackProperties());
        callbackProps = cellstr(string(callbackProps));
        handles = findall(fig);
        for iHandle = 1:numel(handles)
            handle = handles(iHandle);
            for iProp = 1:numel(callbackProps)
                propName = callbackProps{iProp};
                if ~isprop(handle, propName)
                    continue;
                end
                currentCallback = handle.(propName);
                if isempty(currentCallback) || isAlreadyInstrumented(handle, propName)
                    continue;
                end
                wrapped = callbackWrapperForHandle(handle, propName, currentCallback, @trace);
                if isempty(wrapped)
                    continue;
                end
                handle.(propName) = wrapped;
                markInstrumented(handle, propName);
                count = count + 1;
            end
        end
        trace(sprintf('instrumented figure %s callback(s) on %s', ...
            count, handleLabel(fig)));
    end

    function line = appendLineValue(message)
        line = sprintf('[%s] %s', datestr(now, 'HH:MM:SS'), message);
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

function wrapped = callbackWrapperForHandle(handle, propName, callback, traceFcn)
    if isa(callback, 'function_handle')
        wrapped = @wrappedFunctionHandle;
    elseif iscell(callback) && ~isempty(callback) && isa(callback{1}, 'function_handle')
        wrapped = @wrappedCellCallback;
    else
        wrapped = [];
    end

    function varargout = wrappedFunctionHandle(varargin)
        label = callbackTraceLabel(handle, propName, callback);
        traceFcn(sprintf('BEGIN %s', label));
        try
            if nargout == 0
                callback(varargin{:});
                traceFcn(sprintf('END %s', label));
            else
                [varargout{1:nargout}] = callback(varargin{:});
                traceFcn(sprintf('END %s', label));
            end
        catch ME
            traceFcn(sprintf('ERROR %s: %s %s', label, ME.identifier, ME.message));
            rethrow(ME);
        end
    end

    function varargout = wrappedCellCallback(varargin)
        callbackFcn = callback{1};
        callbackArgs = callback(2:end);
        label = callbackTraceLabel(handle, propName, callbackFcn);
        traceFcn(sprintf('BEGIN %s', label));
        try
            if nargout == 0
                callbackFcn(varargin{:}, callbackArgs{:});
                traceFcn(sprintf('END %s', label));
            else
                [varargout{1:nargout}] = callbackFcn(varargin{:}, callbackArgs{:});
                traceFcn(sprintf('END %s', label));
            end
        catch ME
            traceFcn(sprintf('ERROR %s: %s %s', label, ME.identifier, ME.message));
            rethrow(ME);
        end
    end
end

function label = callbackTraceLabel(handle, propName, callback)
    label = sprintf('%s %s', char(string(propName)), handleLabel(handle));
    callbackName = callbackNameText(callback);
    if strlength(callbackName) > 0
        label = sprintf('%s -> %s', label, char(callbackName));
    end
end

function label = handleLabel(handle)
    label = class(handle);
    for propName = {'Text', 'Title', 'Name', 'Tag'}
        prop = propName{1};
        if isprop(handle, prop)
            try
                value = handle.(prop);
                if ~(isempty(value) || (isstring(value) && strlength(value) == 0))
                    label = sprintf('%s "%s"', class(handle), char(string(value)));
                    return;
                end
            catch
            end
        end
    end
end

function txt = callbackNameText(callback)
    txt = "";
    if ~isa(callback, 'function_handle')
        return;
    end
    try
        txt = string(func2str(callback));
    catch
        txt = "";
    end
end

function tf = isAlreadyInstrumented(handle, propName)
    tf = false;
    key = instrumentationAppdataKey(propName);
    try
        tf = isappdata(handle, key);
    catch
        tf = false;
    end
end

function markInstrumented(handle, propName)
    try
        setappdata(handle, instrumentationAppdataKey(propName), true);
    catch
    end
end

function props = defaultCallbackProperties()
    props = {'ButtonPushedFcn', 'ValueChangedFcn', 'SelectionChangedFcn', ...
        'CellEditCallback', 'CellSelectionCallback', ...
        'CloseRequestFcn', 'SizeChangedFcn', ...
        'KeyPressFcn', 'KeyReleaseFcn', ...
        'WindowKeyPressFcn', 'WindowKeyReleaseFcn', ...
        'CheckedNodesChangedFcn', 'NodeExpandedFcn', 'NodeCollapsedFcn'};
end

function key = instrumentationAppdataKey(propName)
    key = ['labkit_ui_debug_instrumented_' char(propName)];
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
