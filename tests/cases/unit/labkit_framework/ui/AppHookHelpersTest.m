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
    checkPromptOutputFile();
    checkPromptOutputFolder();
    checkDefaultDialogFolder();
    checkDefaultOutputFolder();
    checkRequestDispatch();
    checkRequestErrors();
end

function checkDebugLog()
    logFile = [tempname(tempdir) '.log'];
    cleaner = onCleanup(@() cleanupFile(logFile));
    callbackLines = {};
    traceLines = {};
    debug = labkit.ui.debug.context('probe_app', ...
        struct('logFile', logFile, ...
        'logCallback', @captureLine, ...
        'traceCallback', @captureTraceLine));

    assert(debug.enabled, 'Debug log should be enabled by default.');
    assert(debug.traceEnabled, 'Debug trace should be enabled by default.');
    assert(debug.appName == "probe_app", 'Debug log should preserve the app name.');
    assert(debug.logFile == string(logFile), 'Debug log should preserve the log file path.');
    assert(isfield(debug, 'sampleFolder') && isfield(debug, 'outputFolder') && ...
        isfield(debug, 'manifestFile') && isfield(debug, 'recordArtifacts'), ...
        'Debug log should expose app-neutral artifact folders and manifest writer.');
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

    disabled = labkit.ui.debug.context('probe_app', struct('enabled', false));
    disabled.append('ignored');
    disabled.trace('ignored trace');
    assert(isempty(disabled.getLog()), 'Disabled debug logs should ignore appended messages.');

    appendOnly = labkit.ui.debug.context('probe_app', struct('traceEnabled', false));
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
    debug = labkit.ui.debug.context('probe_app', struct());
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
    [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest('probe_app', {}, 0);
    assert(~handled && isempty(outputs) && ~debug.enabled, ...
        'Empty app input should not be handled and should return a disabled debug log.');

    [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
        'probe_app', {'debug'}, 2);
    assert(~handled && isempty(outputs) && debug.enabled && debug.traceEnabled, ...
        'Debug launch dispatch should enable debug logging without consuming app launch.');
    debugLogFile = char(debug.logFile);
    debugSessionFolder = fileparts(debugLogFile);
    cleaner = onCleanup(@() cleanupFolder(debugSessionFolder));
    assert(~isempty(debugLogFile), ...
        'Debug launch dispatch should create a default log file path.');
    assert(exist(debugLogFile, 'file') == 2, ...
        'Debug launch dispatch should initialize the default log file.');
    assert(contains(string(debugLogFile), fullfile('artifacts', 'debug')) && ...
        contains(string(debugLogFile), 'probe_app'), ...
        'Debug launch dispatch should place app logs under artifacts/debug.');
    assert(endsWith(string(debugLogFile), fullfile('trace.log')), ...
        'Debug launch dispatch should create a per-session trace.log.');
    assert(exist(debug.sampleFolder, 'dir') == 7 && ...
        exist(debug.outputFolder, 'dir') == 7, ...
        'Debug launch dispatch should create samples and outputs folders.');

    fileText = string(fileread(debugLogFile));
    assert(contains(fileText, 'probe_app debug log') && ...
        contains(fileText, 'matlab=') && ...
        contains(fileText, 'platform='), ...
        'Debug log files should start with app and environment metadata.');

    debug.trace('dispatch probe');
    debug.recordArtifacts(struct("type", "probeManifest", ...
        "files", "synthetic.csv"));
    fileText = string(fileread(debugLogFile));
    assert(contains(fileText, 'event=dispatch probe'), ...
        'Default debug log files should capture trace lines.');
    assert(isfile(debug.manifestFile), ...
        'Debug artifact manifest writer should write the session manifest.');
    manifestText = string(fileread(debug.manifestFile));
    assert(contains(manifestText, '"type"') && ...
        contains(manifestText, 'probeManifest') && ...
        contains(manifestText, 'sampleFolder'), ...
        'Debug artifact manifest should include caller payload and session folders.');

    req = labkit.contract.requirements("ui", ">=5 <6");
    [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
        'probe_app', {'requirements'}, 1, "Requirements", req);
    assert(handled && numel(outputs) == 1 && isequal(outputs{1}, req) && ~debug.enabled, ...
        'Requirements request should return the app requirement struct without launching.');

    info = struct("name", "probe_app", "displayName", "Probe App", ...
        "family", "Probe", "version", "1.0.0", "updated", "2026-06-23");
    [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
        'probe_app', {'version'}, 1, "Version", info);
    assert(handled && numel(outputs) == 1 && isequal(outputs{1}, info) && ~debug.enabled, ...
        'Version request should return the app version struct without launching.');
    titleText = labkit.ui.runtime.appVersionTitle("Probe App", info);
    assert(titleText == "Probe App v1.0.0 (2026-06-23)", ...
        'App version title helper should include version and update date.');
    retitled = labkit.ui.runtime.appVersionTitle(titleText, info);
    assert(retitled == titleText, ...
        'App version title helper should be idempotent for an already-versioned title.');
end

function checkPromptOutputFile()
    capturedDefault = "";
    outputFolder = tempname(tempdir);
    mkdir(outputFolder);
    cleaner = onCleanup(@() cleanupFolder(outputFolder));

    [filepath, cancelled, file, folder] = labkit.ui.runtime.promptOutputFile( ...
        '*.csv', 'Save CSV', fullfile(pwd, 'unsafe.csv'), ...
        'Chooser', @chooseFile);
    assert(~cancelled, 'Output prompt helper should report a selected file.');
    assert(filepath == string(fullfile(outputFolder, 'result.csv')), ...
        'Output prompt helper should return a full selected path.');
    assert(strcmp(file, 'result.csv') && strcmp(folder, outputFolder), ...
        'Output prompt helper should preserve chooser outputs.');
    assert(~startsWith(capturedDefault, string(testRepoRoot())), ...
        'Output prompt helper should not default into the LabKit runtime folder.');

    [filepath, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        '*.csv', 'Save CSV', 'result.csv', 'Chooser', @cancelFile);
    assert(cancelled && filepath == "", ...
        'Output prompt helper should normalize canceled chooser output.');

    function [file, folder] = chooseFile(~, ~, defaultPath)
        capturedDefault = string(defaultPath);
        file = 'result.csv';
        folder = outputFolder;
    end

    function [file, folder] = cancelFile(~, ~, ~)
        file = 0;
        folder = 0;
    end
end

function checkPromptOutputFolder()
    capturedDefault = "";
    outputFolder = tempname(tempdir);
    mkdir(outputFolder);
    cleaner = onCleanup(@() cleanupFolder(outputFolder));

    [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
        'Select output folder', pwd, 'Chooser', @chooseFolder);
    assert(~cancelled, 'Output folder prompt helper should report a selected folder.');
    assert(folder == string(outputFolder), ...
        'Output folder prompt helper should return the selected folder.');
    assert(~startsWith(capturedDefault, string(testRepoRoot())), ...
        'Output folder prompt helper should not default into the LabKit runtime folder.');

    remembered = labkit.ui.runtime.defaultDialogFolder("output");
    assert(strcmp(remembered, outputFolder), ...
        'Output folder prompt helper should remember existing selected folders.');

    [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
        'Select output folder', outputFolder, 'Chooser', @cancelFolder);
    assert(cancelled && folder == "", ...
        'Output folder prompt helper should normalize canceled chooser output.');

    function folder = chooseFolder(defaultFolder, ~)
        capturedDefault = string(defaultFolder);
        folder = outputFolder;
    end

    function folder = cancelFolder(~, ~)
        folder = 0;
    end
end

function checkDefaultDialogFolder()
    homeFolder = tempname(tempdir);
    mkdir(homeFolder);
    homeCleaner = onCleanup(@() cleanupFolder(homeFolder));

    previousUserProfile = getenv('USERPROFILE');
    previousHome = getenv('HOME');
    hadInputPref = ispref('LabKit', 'LastInputFolder');
    if hadInputPref
        previousInputPref = getpref('LabKit', 'LastInputFolder');
    else
        previousInputPref = '';
    end
    prefCleaner = onCleanup(@() restoreDialogEnvironment( ...
        previousUserProfile, previousHome, hadInputPref, previousInputPref));

    if hadInputPref
        rmpref('LabKit', 'LastInputFolder');
    end
    setenv('USERPROFILE', '');
    setenv('HOME', homeFolder);

    folder = labkit.ui.runtime.defaultDialogFolder("input");
    assert(strcmp(folder, homeFolder), ...
        'Dialog default helper should use HOME when USERPROFILE and remembered folders are unavailable.');
end

function checkDefaultOutputFolder()
    sourceFolder = tempname(tempdir);
    mkdir(sourceFolder);
    cleaner = onCleanup(@() cleanupFolder(sourceFolder));
    firstFile = fullfile(sourceFolder, 'first.png');
    secondFile = fullfile(tempdir, 'second.png');
    fid = fopen(firstFile, 'w');
    fclose(fid);

    folder = labkit.ui.runtime.defaultOutputFolder( ...
        [string(firstFile); string(secondFile)], "exports");
    assert(strcmp(folder, fullfile(sourceFolder, 'exports')), ...
        'Default output folder should use the first source path as the base.');
    assert(exist(folder, 'dir') == 7, ...
        'Default output folder should create the app output subfolder.');

    folderFromSourceFolder = labkit.ui.runtime.defaultOutputFolder(sourceFolder, ...
        "folder_exports");
    assert(strcmp(folderFromSourceFolder, fullfile(sourceFolder, 'folder_exports')), ...
        'Default output folder should accept a source folder directly.');
end

function restoreDialogEnvironment(previousUserProfile, previousHome, hadInputPref, previousInputPref)
    setenv('USERPROFILE', previousUserProfile);
    setenv('HOME', previousHome);
    if hadInputPref
        setpref('LabKit', 'LastInputFolder', previousInputPref);
    elseif ispref('LabKit', 'LastInputFolder')
        rmpref('LabKit', 'LastInputFolder');
    end
end

function checkRequestErrors()
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {42}, 0), ...
        'probe_app:UnsupportedInput', 'Nonstrings should be unsupported app input.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'legacyCommand', 'arg'}, 0), ...
        'probe_app:UnsupportedInput', 'Non-debug string inputs should be rejected.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'__labkit_debug__'}, 0), ...
        'probe_app:UnsupportedInput', 'Internal debug aliases should not be public app input.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'--debug'}, 0), ...
        'probe_app:UnsupportedInput', 'Command-style debug aliases should not be public app input.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'debug'}, 3), ...
        'probe_app:TooManyOutputs', 'Too many debug outputs should fail with the canonical id.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'debug', struct()}, 0), ...
        'probe_app:UnsupportedInput', 'Public debug launch should not accept options.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'requirements', struct()}, 1), ...
        'probe_app:UnsupportedInput', 'Requirements request should not accept options.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'requirements'}, 2), ...
        'probe_app:TooManyOutputs', 'Requirements request should return at most one output.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'version', struct()}, 1), ...
        'probe_app:UnsupportedInput', 'Version request should not accept options.');
    assertThrows(@() labkit.ui.runtime.dispatchRequest('probe_app', {'version'}, 2), ...
        'probe_app:TooManyOutputs', 'Version request should return at most one output.');
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

function cleanupFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
