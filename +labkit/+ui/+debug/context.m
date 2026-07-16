function debugContext = context(appName, opts)
%CONTEXT Create an app-neutral callback tracing and diagnostic context.
%
% Usage:
%   debug = labkit.ui.debug.context(appName)
%   debug = labkit.ui.debug.context(appName, opts)
%
% Inputs:
%   appName - Text scalar identifying the app in every structured trace line
%       and diagnostic report.
%   opts - Optional scalar struct described below. Default: struct().
%
% Options:
%   enabled - Logical master switch. A disabled context ignores captured
%       messages and does not create artifact folders. Default: true.
%   traceEnabled - Logical switch for trace and callback instrumentation.
%       Default: enabled.
%   logFile - Text file path. Existing content is replaced when the context is
%       created, then every captured line is appended. Default: "".
%   logCallback - Function handle called as logCallback(line) for every
%       captured append or trace line. Default: [].
%   traceCallback - Function handle called as traceCallback(line) only for
%       structured trace lines. Default: [].
%   stallTimeoutSeconds - Nonnegative callback duration in seconds before an
%       instrumented operation writes a stalled-operation report. Default: 30.
%   crashReportFile - Diagnostic report path. By default, uses the logFile
%       folder and base name with a _crash_report.txt suffix.
%   activeOperationFile - Path written at callback start and removed after
%       successful or failed completion. A MATLAB process failure can therefore
%       leave the last active callback on disk. The default is derived from
%       logFile with an _active_operation.txt suffix.
%   artifactFolder - Root folder for debug sample packs. Default: the logFile
%       folder.
%   sampleFolder - Folder for copied or synthetic input samples. Default:
%       fullfile(artifactFolder,"samples").
%   outputFolder - Folder for debug outputs. Default:
%       fullfile(artifactFolder,"outputs").
%   manifestFile - JSON manifest path. Default:
%       fullfile(artifactFolder,"manifest.json").
%
% Outputs:
%   debugContext - Scalar struct, shown as debug in the usage syntax, containing
%       configuration fields and the methods below.
%
% Context Fields:
%   appName - Normalized app name as a string scalar.
%   enabled - Effective master switch.
%   traceEnabled - Effective trace switch.
%   logFile - Effective log path.
%   crashReportFile - Effective caught-error and stall-report path.
%   activeOperationFile - Effective active-operation marker path.
%   artifactFolder - Effective artifact root.
%   sampleFolder - Effective sample folder.
%   outputFolder - Effective output folder.
%   manifestFile - Effective manifest path.
%
% Context Methods:
%   append(message) - Add one timestamped human-readable log line.
%   trace(event) - Add a structured app-level trace with reason "internal".
%   trace(component,event,reason) - Add a trace containing stable app,
%       component, event, and reason fields.
%   reportException(event,exception) - Trace and report an app-level exception.
%   reportException(component,event,exception) - Trace and report a component
%       exception. Non-MException values are recorded as caught error text.
%   setTraceCallback(callback) - Replace the trace-only callback.
%   attachTextLog(textArea) - Send future trace lines to a LabKit log text area.
%   wrapCallback(name,callback) - Return a callback that records BEGIN, END,
%       elapsed operation state, stalls, and errors while preserving outputs.
%   instrumentFigure(fig) - Wrap supported callbacks already installed on a
%       figure and its descendants; return the number wrapped.
%   instrumentFigure(fig,opts) - Use opts.callbackProperties instead of the
%       standard callback-property list.
%   recordArtifacts(manifest) - Write manifest plus effective debug paths to
%       manifestFile when that path is configured.
%   getLog() - Return captured lines as a column cell array of character rows.
%
% Description:
%   context provides opt-in diagnostics without coupling an app to a particular
%   log panel. Instrumented callbacks are rethrown after reporting, so debugging
%   does not change error control flow. File-chooser trace events suppress stall
%   reports while a known modal dialog is active. With no file paths configured,
%   messages remain in memory and no files or folders are created.
%
% Example:
%   debug = labkit.ui.debug.context("example_app");
%   debug.trace("loader", "file parsed", "user");
%   lines = debug.getLog();
%   assert(contains(lines{end}, "component=loader"))
%
% See also labkit.ui.runtime.launch

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
    modalDialogDepth = 0;

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
        updateModalDialogState(component, event);
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
            count, debugHandleLabel(fig)));
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
                'TimerFcn', @(~,~) writeStallReportIfNotModal(op));
            start(timerObj);
        catch
            timerObj = [];
        end
    end

    function writeStallReportIfNotModal(op)
        if modalDialogDepth > 0
            appendLineValue(sprintf('[debug] app=%s component=debug event=stall timer skipped during modal dialog operation=%s reason=internal', ...
                traceValue(appName), traceValue(op.label)));
            return;
        end
        writeOperationReport("stalled", op, []);
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

    function updateModalDialogState(component, event)
        if string(component) ~= "filePanel"
            return;
        end
        eventText = string(event);
        if contains(eventText, "file chooser start") || ...
                contains(eventText, "folder chooser start") || ...
                contains(eventText, "dialog provider start") || ...
                contains(eventText, "large folder prompt")
            modalDialogDepth = modalDialogDepth + 1;
        elseif contains(eventText, "file chooser end") || ...
                contains(eventText, "folder chooser end") || ...
                contains(eventText, "dialog provider end") || ...
                contains(eventText, "paths selected")
            modalDialogDepth = max(0, modalDialogDepth - 1);
        end
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
