function debugContext = createContext(appName, opts)
%CREATEDEBUGCONTEXT Create an app-neutral debug and trace context.
%
% Usage:
%   debug = labkit.ui.diag.createContext("labkit_Example_app", opts);
%   debug.append("Loaded file");
%   debug.trace("button pressed");
%   debug.trace("scaleBar", "reference changed", "user");
%   debug.reportException("load", caughtException);
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
%       stallTimeoutSeconds - positive scalar, default 30. Instrumented
%           callbacks still running after this duration write a crash report.
%       crashReportFile - char/string filepath, default derived from logFile.
%       activeOperationFile - char/string filepath, default derived from
%           logFile. This file is written at callback start and removed only
%           after callback completion so a process crash leaves the active
%           callback visible on disk.
%       artifactFolder, sampleFolder, outputFolder, manifestFile -
%           char/string debug artifact paths derived from logFile by default.
%
% Output:
%   debugContext - struct with appName, file paths, append/trace/report
%       callbacks, figure instrumentation, recordArtifacts, and getLog.
%       Trace lines include stable app, component, event, and reason fields.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    appName = string(appName);
    enabled = optionValue(opts, 'enabled', true);
    traceEnabled = optionValue(opts, 'traceEnabled', enabled);
    logFile = string(optionValue(opts, 'logFile', ""));
    logCallback = optionValue(opts, 'logCallback', []);
    traceCallback = optionValue(opts, 'traceCallback', []);
    crashReportFile = string(optionValue(opts, 'crashReportFile', ...
        defaultReportFile(logFile, "crash_report")));
    activeOperationFile = string(optionValue(opts, 'activeOperationFile', ...
        defaultReportFile(logFile, "active_operation")));
    artifacts = debugArtifactPaths(opts, logFile, enabled);
    artifactFolder = artifacts.artifactFolder;
    sampleFolder = artifacts.sampleFolder;
    outputFolder = artifacts.outputFolder;
    manifestFile = artifacts.manifestFile;
    stallTimeoutSeconds = normalizePositiveScalar( ...
        optionValue(opts, 'stallTimeoutSeconds', 30), 30);
    lines = {};

    if enabled && strlength(logFile) > 0
        initializeLogFile(logFile, appName);
    end
    debugContext = struct();
    debugContext.appName = appName;
    debugContext.enabled = logical(enabled);
    debugContext.traceEnabled = logical(traceEnabled);
    debugContext.logFile = logFile;
    debugContext.crashReportFile = crashReportFile;
    debugContext.activeOperationFile = activeOperationFile;
    debugContext.artifactFolder = artifactFolder;
    debugContext.sampleFolder = sampleFolder;
    debugContext.outputFolder = outputFolder;
    debugContext.manifestFile = manifestFile;
    debugContext.append = @append;
    debugContext.trace = @trace;
    debugContext.reportException = @reportException;
    debugContext.setTraceCallback = @setTraceCallback;
    debugContext.attachTextLog = @attachTextLog;
    debugContext.wrapCallback = @wrapCallback;
    debugContext.instrumentFigure = @instrumentFigure;
    debugContext.recordArtifacts = @recordArtifacts;
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

    function reportException(component, event, exception)
        if nargin < 3
            exception = event;
            event = component;
            component = "app";
        end
        if ~isa(exception, 'MException')
            trace(component, sprintf('ERROR %s: %s', ...
                char(string(event)), char(string(exception))), 'caught');
            return;
        end

        label = sprintf('%s %s', char(string(component)), char(string(event)));
        trace(component, sprintf('ERROR %s: %s %s', ...
            char(string(event)), exception.identifier, exception.message), 'caught');
        op = completedOperation(label);
        writeOperationReport("caught_error", op, exception);
    end

    function recordArtifacts(manifest)
        if ~enabled || strlength(manifestFile) == 0
            return;
        end
        metadata = struct( ...
            "appName", appName, ...
            "logFile", logFile, ...
            "artifactFolder", artifactFolder, ...
            "sampleFolder", sampleFolder, ...
            "outputFolder", outputFolder);
        writeDebugManifest(manifestFile, manifest, metadata);
        trace("debugArtifacts", "manifest written", "internal");
    end

    function attachTextLog(textArea)
        setTraceCallback(@appendTraceToTextLog);

        function appendTraceToTextLog(line)
            if isempty(textArea) || ~isvalid(textArea)
                return;
            end
            appendTextLog(textArea, line);
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
            op = startOperation(callbackName);
            trace(sprintf('BEGIN %s', callbackName));
            try
                if nargout == 0
                    originalCallback(varargin{:});
                    trace(sprintf('END %s', callbackName));
                    finishOperation(op, "completed", []);
                else
                    [varargout{1:nargout}] = originalCallback(varargin{:});
                    trace(sprintf('END %s', callbackName));
                    finishOperation(op, "completed", []);
                end
            catch ME
                trace(sprintf('ERROR %s: %s %s', ...
                    callbackName, ME.identifier, ME.message));
                finishOperation(op, "error", ME);
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
                wrapped = callbackWrapperForHandle(handle, propName, currentCallback, ...
                    @trace, @startOperation, @finishOperation);
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

    function op = startOperation(label)
        op = emptyOperation();
        if ~enabled || ~traceEnabled
            return;
        end
        op = struct( ...
            'id', operationId(), ...
            'label', char(string(label)), ...
            'startedAt', datestr(now, 31), ...
            'startTic', tic, ...
            'timer', []);
        writeOperationReport("active", op, []);
        op.timer = startStallTimer(op);
    end

    function op = completedOperation(label)
        op = struct( ...
            'id', operationId(), ...
            'label', char(string(label)), ...
            'startedAt', datestr(now, 31), ...
            'startTic', tic, ...
            'timer', []);
    end

    function finishOperation(op, status, exception)
        if ~isstruct(op) || ~isfield(op, 'id') || strlength(string(op.id)) == 0
            return;
        end
        stopStallTimer(op);
        if status == "error"
            writeOperationReport("error", op, exception);
        end
        removeActiveOperationFile();
    end

    function timerObj = startStallTimer(op)
        timerObj = [];
        if stallTimeoutSeconds <= 0 || strlength(crashReportFile) == 0
            return;
        end
        try
            timerObj = timer( ...
                'ExecutionMode', 'singleShot', ...
                'StartDelay', stallTimeoutSeconds, ...
                'Name', sprintf('labkit_stall_%s', op.id), ...
                'TimerFcn', @(~,~) writeOperationReport("stalled", op, []));
            start(timerObj);
        catch
            timerObj = [];
        end
    end

    function stopStallTimer(op)
        if ~isfield(op, 'timer') || isempty(op.timer)
            return;
        end
        try
            stop(op.timer);
            delete(op.timer);
        catch
        end
    end

    function writeOperationReport(status, op, exception)
        filepath = crashReportFile;
        if status == "active"
            filepath = activeOperationFile;
        end
        if strlength(filepath) == 0
            return;
        end

        fid = fopen(filepath, 'w');
        if fid < 0
            return;
        end
        cleaner = onCleanup(@() fclose(fid));
        fprintf(fid, 'LabKit app diagnostic report\n');
        fprintf(fid, 'created=%s\n', datestr(now, 31));
        fprintf(fid, 'app=%s\n', char(appName));
        fprintf(fid, 'status=%s\n', char(status));
        fprintf(fid, 'operation=%s\n', sanitizeReportLine(op.label));
        fprintf(fid, 'operation_id=%s\n', sanitizeReportLine(op.id));
        fprintf(fid, 'operation_started=%s\n', sanitizeReportLine(op.startedAt));
        fprintf(fid, 'elapsed_seconds=%.3f\n', elapsedSeconds(op));
        fprintf(fid, 'stall_timeout_seconds=%.3f\n', stallTimeoutSeconds);
        fprintf(fid, 'matlab=%s\n', version);
        fprintf(fid, 'platform=%s\n', computer);
        if ~isempty(exception) && isa(exception, 'MException')
            fprintf(fid, 'error_id=%s\n', sanitizeReportLine(exception.identifier));
            fprintf(fid, 'error_message=%s\n', sanitizeReportLine(exception.message));
            writeStack(fid, exception);
        end
        fprintf(fid, '\nrecent_operations:\n');
        writeRecentOperations(fid, recentOperationLines(12));
        fprintf(fid, '\nrecent_log:\n');
        recent = recentLines(40);
        for k = 1:numel(recent)
            fprintf(fid, '%s\n', sanitizeReportLine(recent{k}));
        end
    end

    function removeActiveOperationFile()
        if strlength(activeOperationFile) == 0
            return;
        end
        try
            if exist(activeOperationFile, 'file') == 2
                delete(activeOperationFile);
            end
        catch
        end
    end

    function recent = recentLines(maxCount)
        first = max(1, numel(lines) - maxCount + 1);
        recent = lines(first:end);
    end

    function recent = recentOperationLines(maxCount)
        recent = {};
        for k = 1:numel(lines)
            line = string(lines{k});
            if isReproTraceLine(line)
                recent{end + 1, 1} = char(line);
            end
        end
        first = max(1, numel(recent) - maxCount + 1);
        recent = recent(first:end);
    end
end

function appendTextLog(textArea, msg)
    timestamp = datestr(now, 'HH:MM:SS');
    old = textArea.Value;
    old{end + 1} = sprintf('[%s] %s', timestamp, char(msg));
    textArea.Value = old;
    if shouldFollowLatest(textArea)
        scrollLogToBottom(textArea);
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

function wrapped = callbackWrapperForHandle(handle, propName, callback, traceFcn, startOperationFcn, finishOperationFcn)
    if isa(callback, 'function_handle')
        wrapped = @wrappedFunctionHandle;
    elseif iscell(callback) && ~isempty(callback) && isa(callback{1}, 'function_handle')
        wrapped = @wrappedCellCallback;
    else
        wrapped = [];
    end

    function varargout = wrappedFunctionHandle(varargin)
        label = callbackTraceLabel(handle, propName, callback);
        op = startOperationFcn(label);
        traceFcn(sprintf('BEGIN %s', label));
        try
            if nargout == 0
                callback(varargin{:});
                traceFcn(sprintf('END %s', label));
                finishOperationFcn(op, "completed", []);
            else
                [varargout{1:nargout}] = callback(varargin{:});
                traceFcn(sprintf('END %s', label));
                finishOperationFcn(op, "completed", []);
            end
        catch ME
            traceFcn(sprintf('ERROR %s: %s %s', label, ME.identifier, ME.message));
            finishOperationFcn(op, "error", ME);
            rethrow(ME);
        end
    end

    function varargout = wrappedCellCallback(varargin)
        callbackFcn = callback{1};
        callbackArgs = callback(2:end);
        label = callbackTraceLabel(handle, propName, callbackFcn);
        op = startOperationFcn(label);
        traceFcn(sprintf('BEGIN %s', label));
        try
            if nargout == 0
                callbackFcn(varargin{:}, callbackArgs{:});
                traceFcn(sprintf('END %s', label));
                finishOperationFcn(op, "completed", []);
            else
                [varargout{1:nargout}] = callbackFcn(varargin{:}, callbackArgs{:});
                traceFcn(sprintf('END %s', label));
                finishOperationFcn(op, "completed", []);
            end
        catch ME
            traceFcn(sprintf('ERROR %s: %s %s', label, ME.identifier, ME.message));
            finishOperationFcn(op, "error", ME);
            rethrow(ME);
        end
    end
end

function label = callbackTraceLabel(handle, propName, callback)
    label = sprintf('%s %s', char(string(propName)), handleLabel(handle));
    callbackName = originalCallbackName(handle);
    if strlength(callbackName) == 0
        callbackName = callbackNameText(callback);
    end
    if strlength(callbackName) > 0
        label = sprintf('%s -> %s', label, char(callbackName));
    end
end

function txt = originalCallbackName(handle)
    txt = "";
    try
        if isappdata(handle, 'labkit_ui_original_callback_name')
            txt = string(getappdata(handle, 'labkit_ui_original_callback_name'));
        end
    catch
        txt = "";
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
    fprintf(fid, 'created=%s\n', datestr(now, 31));
    fprintf(fid, 'matlab=%s\n', version);
    fprintf(fid, 'platform=%s\n', computer);
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

function filepath = defaultReportFile(logFile, suffix)
    logFile = string(logFile);
    if strlength(logFile) == 0
        filepath = "";
        return;
    end
    [folder, name] = fileparts(logFile);
    filepath = fullfile(folder, sprintf('%s_%s.txt', char(name), char(suffix)));
end

function value = normalizePositiveScalar(value, defaultValue)
    try
        value = double(value);
        if ~isscalar(value) || ~isfinite(value) || value < 0
            value = defaultValue;
        end
    catch
        value = defaultValue;
    end
end

function op = emptyOperation()
    op = struct('id', '', 'label', '', 'startedAt', '', ...
        'startTic', [], 'timer', []);
end

function id = operationId()
    [~, seed] = fileparts(tempname);
    id = char(matlab.lang.makeValidName(seed));
end

function seconds = elapsedSeconds(op)
    seconds = NaN;
    try
        seconds = toc(op.startTic);
    catch
    end
end

function text = sanitizeReportLine(value)
    text = char(string(value));
    text = strrep(text, newline, ' ');
    text = strrep(text, sprintf('\r'), ' ');
end

function writeStack(fid, exception)
    stack = exception.stack;
    for k = 1:numel(stack)
        fprintf(fid, 'stack_%d=%s:%d %s\n', k, ...
            sanitizeReportLine(stack(k).file), stack(k).line, ...
            sanitizeReportLine(stack(k).name));
    end
end

function writeRecentOperations(fid, recent)
    if isempty(recent)
        fprintf(fid, '(none captured)\n');
        return;
    end
    for k = 1:numel(recent)
        fprintf(fid, '%d. %s\n', k, sanitizeReportLine(recent{k}));
    end
end

function tf = isReproTraceLine(line)
    tf = contains(line, '[debug]') && ...
        (contains(line, 'BEGIN ') || contains(line, 'ERROR ') || ...
        contains(line, 'component=filePanel') || ...
        contains(line, ' callback start') || contains(line, ' callback end'));
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
