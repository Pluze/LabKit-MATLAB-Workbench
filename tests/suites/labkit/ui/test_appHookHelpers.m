function test_appHookHelpers()
%TEST_APPHOOKHELPERS Verify internal app hook dispatch and debug log helpers.

    checkDebugLog();
    checkRequestDispatch();
    checkRequestErrors();
end

function checkDebugLog()
    logFile = [tempname(tempdir) '.log'];
    cleaner = onCleanup(@() cleanupFile(logFile)); %#ok<NASGU>
    callbackLines = {};
    debug = labkit.ui.createAppDebugLog('probe_app', ...
        struct('logFile', logFile, 'logCallback', @captureLine));

    assert(debug.enabled, 'Debug log should be enabled by default.');
    assert(debug.appName == "probe_app", 'Debug log should preserve the app name.');
    assert(debug.logFile == string(logFile), 'Debug log should preserve the log file path.');
    debug.append('hello');
    lines = debug.getLog();
    assert(numel(lines) == 1 && contains(lines{1}, 'hello'), ...
        'Debug log should capture appended messages.');
    assert(numel(callbackLines) == 1 && contains(callbackLines{1}, 'hello'), ...
        'Debug log should call the append callback.');
    assert(contains(string(fileread(logFile)), 'hello'), ...
        'Debug log should mirror appended messages to the log file.');

    disabled = labkit.ui.createAppDebugLog('probe_app', struct('enabled', false));
    disabled.append('ignored');
    assert(isempty(disabled.getLog()), 'Disabled debug logs should ignore appended messages.');

    function captureLine(line)
        callbackLines{end+1, 1} = line;
    end
end

function checkRequestDispatch()
    handlers = struct( ...
        'command', {'echo'}, ...
        'minArgs', {1}, ...
        'maxArgs', {2}, ...
        'maxOutputs', {2}, ...
        'run', {@runEcho});

    [handled, outputs, debug] = labkit.ui.handleAppRequest('probe_app', {}, 0, handlers);
    assert(~handled && isempty(outputs) && ~debug.enabled, ...
        'Empty app input should not be handled and should return a disabled debug log.');

    [handled, outputs] = labkit.ui.handleAppRequest( ...
        'probe_app', {'__labkit_test__', 'echo', 'one', 'two'}, 2, handlers);
    assert(handled && isequal(outputs, {'one', 'two'}), ...
        'Test hook dispatch should return requested handler outputs.');

    [handled, outputs, debug] = labkit.ui.handleAppRequest( ...
        'probe_app', {'__labkit_debug__', struct()}, 2, handlers);
    assert(~handled && isempty(outputs) && debug.enabled, ...
        'Debug hook dispatch should enable debug logging without consuming app launch.');
end

function checkRequestErrors()
    handlers = struct( ...
        'command', {'echo'}, ...
        'minArgs', {1}, ...
        'maxArgs', {1}, ...
        'maxOutputs', {1}, ...
        'run', {@runEcho});

    assertThrows(@() labkit.ui.handleAppRequest('probe_app', {42}, 0, handlers), ...
        'probe_app:UnsupportedInput', 'Nonstrings should be unsupported app input.');
    assertThrows(@() labkit.ui.handleAppRequest('probe_app', {'__labkit_test__'}, 0, handlers), ...
        'probe_app:InvalidTestRequest', 'Test hooks require a command name.');
    assertThrows(@() labkit.ui.handleAppRequest('probe_app', {'__labkit_test__', 'missing'}, 0, handlers), ...
        'probe_app:UnknownTestCommand', 'Unknown test commands should fail with the canonical id.');
    assertThrows(@() labkit.ui.handleAppRequest('probe_app', {'__labkit_test__', 'echo'}, 0, handlers), ...
        'probe_app:InvalidTestArguments', 'Invalid test argument counts should fail with the canonical id.');
    assertThrows(@() labkit.ui.handleAppRequest('probe_app', {'__labkit_test__', 'echo', 'one'}, 2, handlers), ...
        'probe_app:TooManyOutputs', 'Too many requested outputs should fail with the canonical id.');
end

function outputs = runEcho(args)
    outputs = args;
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
