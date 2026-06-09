function debugContext = createContext(appName, opts)
%CREATEDEBUGCONTEXT Create an app-neutral debug and trace context.
%
% Usage:
%   debug = labkit.ui.diag.createContext("labkit_Example_app", opts);
%   debug.append("Loaded file");
%   debug.trace("button pressed");
%   debug.trace("scaleBar", "reference changed", "user");
%   debug.attachTextLog(txtLog);
%   debug.instrumentFigure(fig);
%
% Inputs:
%   appName - app entry-point name stored in debugContext.appName and trace.
%   opts - optional struct with fields:
%       enabled - logical, default true. Disabled contexts ignore append/trace.
%       traceEnabled - logical, default same as enabled.
%       logFile - char/string filepath, default ''. Appended and trace lines
%           are mirrored to this file when enabled.
%       logCallback - function handle, default []. Called for every captured
%           line as logCallback(line).
%       traceCallback - function handle, default []. Called only for trace
%           lines as traceCallback(line).
%
% Output:
%   debugContext - struct with appName, enabled, traceEnabled, logFile,
%       append, trace, setTraceCallback, attachTextLog, wrapCallback,
%       instrumentFigure, and getLog. Trace lines include stable app,
%       component, event, and reason fields. Default figure instrumentation
%       wraps high-level component callbacks and intentionally skips pointer,
%       drag, and scroll.

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

    debugContext = struct();
    debugContext.appName = appName;
    debugContext.enabled = logical(enabled);
    debugContext.traceEnabled = logical(traceEnabled);
    debugContext.logFile = logFile;
    debugContext.append = @append;
    debugContext.trace = @trace;
    debugContext.setTraceCallback = @setTraceCallback;
    debugContext.attachTextLog = @attachTextLog;
    debugContext.wrapCallback = @wrapCallback;
    debugContext.instrumentFigure = @instrumentFigure;
    debugContext.getLog = @getLog;

    function append(message)
        if ~enabled
            return;
        end
        appendLineValue(char(message));
    end

    function trace(component, event, reason)
        if ~enabled || ~traceEnabled
            return;
        end
        if nargin < 2
            event = component;
            component = "app";
        end
        if nargin < 3 || isempty(reason)
            reason = "internal";
        end
        line = appendLineValue(sprintf('[debug] app=%s component=%s event=%s reason=%s', ...
            traceValue(appName), traceValue(component), ...
            traceValue(event), traceValue(reason)));
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
            labkit.ui.view.update(textArea, 'appendLog', line);
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
        trace(sprintf('instrumented figure %d callback(s) on %s', ...
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

function text = traceValue(value)
    text = char(string(value));
    text = strrep(text, newline, ' ');
    text = strrep(text, sprintf('\r'), ' ');
end
