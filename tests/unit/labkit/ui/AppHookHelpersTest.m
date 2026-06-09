classdef AppHookHelpersTest < matlab.unittest.TestCase
    %APPHOOKHELPERSTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_appHookHelpers(testCase)
            setupLabKitTestPath();
            verify_appHookHelpers();
        end
    end
end

function verify_appHookHelpers()
%TEST_APPHOOKHELPERS Verify internal app hook dispatch and debug log helpers.

    checkDebugLog();
    checkCallbackWrapper();
    checkRequestDispatch();
    checkRequestErrors();
end

function checkDebugLog()
    logFile = [tempname(tempdir) '.log'];
    cleaner = onCleanup(@() cleanupFile(logFile));
    callbackLines = {};
    traceLines = {};
    debug = labkit.ui.diag.createContext('probe_app', ...
        struct('logFile', logFile, ...
        'logCallback', @captureLine, ...
        'traceCallback', @captureTraceLine));

    assert(debug.enabled, 'Debug log should be enabled by default.');
    assert(debug.traceEnabled, 'Debug trace should be enabled by default.');
    assert(debug.appName == "probe_app", 'Debug log should preserve the app name.');
    assert(debug.logFile == string(logFile), 'Debug log should preserve the log file path.');
    debug.append('hello');
    debug.trace('details');
    lines = debug.getLog();
    assert(numel(lines) == 2 && contains(lines{1}, 'hello'), ...
        'Debug log should capture appended messages.');
    assert(contains(lines{2}, '[debug] app=probe_app component=app event=details reason=internal'), ...
        'Debug log should capture trace messages with app-scoped debug prefix.');
    assert(numel(callbackLines) == 2 && contains(callbackLines{1}, 'hello') && ...
        contains(callbackLines{2}, 'app=probe_app') && ...
        contains(callbackLines{2}, 'event=details') && ...
        contains(callbackLines{2}, 'reason=internal'), ...
        'Debug log should call the append callback for append and trace lines.');
    assert(numel(traceLines) == 1 && contains(traceLines{1}, 'app=probe_app') && ...
        contains(traceLines{1}, 'event=details') && ...
        contains(traceLines{1}, 'reason=internal'), ...
        'Debug log should call the trace-only callback for trace lines.');
    fileText = string(fileread(logFile));
    assert(contains(fileText, 'hello') && contains(fileText, 'app=probe_app') && ...
        contains(fileText, 'event=details'), ...
        'Debug log should mirror appended and trace messages to the log file.');

    disabled = labkit.ui.diag.createContext('probe_app', struct('enabled', false));
    disabled.append('ignored');
    disabled.trace('ignored trace');
    assert(isempty(disabled.getLog()), 'Disabled debug logs should ignore appended messages.');

    appendOnly = labkit.ui.diag.createContext('probe_app', struct('traceEnabled', false));
    appendOnly.append('kept');
    appendOnly.trace('hidden');
    appendOnlyLines = appendOnly.getLog();
    assert(numel(appendOnlyLines) == 1 && contains(appendOnlyLines{1}, 'kept') && ...
        ~contains(strjoin(appendOnlyLines, newline), 'hidden'), ...
        'traceEnabled=false should preserve append messages and suppress trace messages.');

    function captureLine(line)
        callbackLines{end+1, 1} = line;
    end

    function captureTraceLine(line)
        traceLines{end+1, 1} = line;
    end
end

function checkCallbackWrapper()
    callbackCalls = 0;
    debug = labkit.ui.diag.createContext('probe_app', struct());
    wrapped = debug.wrapCallback('sample callback', @sampleCallback);

    wrapped('source', 'event');
    lines = string(debug.getLog());
    assert(callbackCalls == 1, 'Wrapped callbacks should call the original function.');
    assert(any(contains(lines, 'BEGIN sample callback')) && ...
        any(contains(lines, 'END sample callback')), ...
        'Wrapped callbacks should trace BEGIN and END messages.');

    failing = debug.wrapCallback('failing callback', @failingCallback);
    assertThrows(@() failing([], []), 'probe_app:ExpectedFailure', ...
        'Wrapped callbacks should rethrow original callback errors.');
    lines = string(debug.getLog());
    assert(any(contains(lines, 'ERROR failing callback')), ...
        'Wrapped callbacks should trace ERROR messages before rethrowing.');

    function sampleCallback(varargin)
        callbackCalls = callbackCalls + 1;
    end

    function failingCallback(varargin)
        error('probe_app:ExpectedFailure', 'Expected failure.');
    end
end

function checkRequestDispatch()
    [handled, outputs, debug] = labkit.ui.app.dispatchRequest('probe_app', {}, 0);
    assert(~handled && isempty(outputs) && ~debug.enabled, ...
        'Empty app input should not be handled and should return a disabled debug log.');

    [handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
        'probe_app', {'__labkit_debug__', struct()}, 2);
    assert(~handled && isempty(outputs) && debug.enabled && debug.traceEnabled, ...
        'Debug hook dispatch should enable debug logging without consuming app launch.');

    [handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
        'probe_app', {'debug'}, 2);
    assert(~handled && isempty(outputs) && debug.enabled && debug.traceEnabled, ...
        'Debug launch dispatch should accept the user-facing debug alias.');

    [handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
        'probe_app', {'--debug', struct('traceEnabled', false)}, 2);
    assert(~handled && isempty(outputs) && debug.enabled && ~debug.traceEnabled, ...
        'Debug launch dispatch should preserve explicit traceEnabled=false.');
end

function checkRequestErrors()
    assertThrows(@() labkit.ui.app.dispatchRequest('probe_app', {42}, 0), ...
        'probe_app:UnsupportedInput', 'Nonstrings should be unsupported app input.');
    assertThrows(@() labkit.ui.app.dispatchRequest('probe_app', {'legacyCommand', 'arg'}, 0), ...
        'probe_app:UnsupportedInput', 'Non-debug string inputs should be rejected.');
    assertThrows(@() labkit.ui.app.dispatchRequest('probe_app', {'debug'}, 3), ...
        'probe_app:TooManyOutputs', 'Too many debug outputs should fail with the canonical id.');
    assertThrows(@() labkit.ui.app.dispatchRequest('probe_app', {'debug', 42}, 0), ...
        'probe_app:InvalidDebugOptions', 'Debug options should be a struct.');
    assertThrows(@() labkit.ui.app.dispatchRequest('probe_app', {'debug', struct(), struct()}, 0), ...
        'probe_app:InvalidDebugOptions', 'Debug requests should accept at most one options struct.');
end

function assertThrows(fn, expectedIdentifier, label)
    try
        fn();
    catch ME
        assert(strcmp(ME.identifier, expectedIdentifier), ...
            '%s Expected %s but caught %s.', label, expectedIdentifier, ME.identifier);
        return;
    end
    error('%s Expected an error with identifier %s.', label, expectedIdentifier);
end

function cleanupFile(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
