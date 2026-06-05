function [handled, outputs, debugLog] = handleAppRequest(appName, args, nout, handlers)
%HANDLEAPPREQUEST Dispatch internal app test/debug requests.
%
% Usage:
%   [handled, outputs, debugLog] = labkit.ui.handleAppRequest( ...
%       "labkit_Example_app", varargin, nargout, handlers);
%
% Inputs:
%   appName - app entry-point name used to build app-scoped error IDs.
%   args - input argument cell from the app entry point.
%   nout - requested output count from the app entry point.
%   handlers - struct array with fields:
%       command - string command name used after "__labkit_test__".
%       minArgs - minimum number of command arguments after command.
%       maxArgs - maximum number of command arguments after command.
%       maxOutputs - maximum number of outputs the command may return.
%       run - function handle accepting a cell array of command arguments and
%             returning a cell array of output values.
%
% Outputs:
%   handled - true when a "__labkit_test__" request was dispatched.
%   outputs - cell array to assign to varargout for handled test requests.
%   debugLog - debug logger from labkit.ui.createAppDebugLog. For normal app
%       launches this is a disabled in-memory logger; for "debug",
%       "--debug", "-debug", or "__labkit_debug__" launches it is enabled
%       with trace logging and may mirror messages to opts.logFile or
%       opts.logCallback. Debug launch requests do not consume app launch.

    appName = char(appName);
    handled = false;
    outputs = {};
    debugLog = labkit.ui.createAppDebugLog(appName, struct('enabled', false));

    if nargin < 4
        handlers = struct('command', {}, 'minArgs', {}, ...
            'maxArgs', {}, 'maxOutputs', {}, 'run', {});
    end
    if isempty(args)
        return;
    end
    if ~(ischar(args{1}) || (isstring(args{1}) && isscalar(args{1})))
        error(errorId(appName, 'UnsupportedInput'), ...
            '%s does not accept input arguments.', appName);
    end

    request = string(args{1});
    if isDebugRequest(request)
        if nout > 2
            error(errorId(appName, 'TooManyOutputs'), ...
                '%s debug mode returns at most the app figure and debug log.', appName);
        end
        opts = debugOptions(appName, request, args);
        debugLog = labkit.ui.createAppDebugLog(appName, opts);
        return;
    end

    switch request
        case "__labkit_test__"
            handled = true;
            outputs = dispatchTestRequest(appName, args(2:end), nout, handlers);
        otherwise
            error(errorId(appName, 'UnsupportedInput'), ...
                '%s does not accept input arguments.', appName);
    end
end

function tf = isDebugRequest(request)
    tf = any(request == ["__labkit_debug__", "debug", "-debug", "--debug"]);
end

function opts = debugOptions(appName, request, args)
    opts = struct();
    if numel(args) > 2
        error(errorId(appName, 'InvalidTestRequest'), ...
            '%s accepts at most one options struct.', char(request));
    elseif numel(args) == 2
        opts = args{2};
    end
    if ~isstruct(opts)
        error(errorId(appName, 'InvalidTestRequest'), ...
            '%s options must be a struct.', char(request));
    end
    opts.enabled = true;
    if ~isfield(opts, 'traceEnabled')
        opts.traceEnabled = true;
    end
end

function outputs = dispatchTestRequest(appName, requestArgs, nout, handlers)
    if isempty(requestArgs) || ...
            ~(ischar(requestArgs{1}) || (isstring(requestArgs{1}) && isscalar(requestArgs{1})))
        error(errorId(appName, 'InvalidTestRequest'), ...
            '__labkit_test__ requires a string command name.');
    end

    validateHandlers(appName, handlers);
    command = string(requestArgs{1});
    commandArgs = requestArgs(2:end);
    match = find(strcmp(command, string({handlers.command})), 1, 'first');
    if isempty(match)
        error(errorId(appName, 'UnknownTestCommand'), ...
            'Unknown __labkit_test__ command: %s.', command);
    end

    handler = handlers(match);
    argCount = numel(commandArgs);
    if argCount < handler.minArgs || argCount > handler.maxArgs
        error(errorId(appName, 'InvalidTestArguments'), ...
            'Command %s expects %d to %d argument(s), got %d.', ...
            command, handler.minArgs, handler.maxArgs, argCount);
    end
    if nout > handler.maxOutputs
        error(errorId(appName, 'TooManyOutputs'), ...
            'Command %s returns at most %d output(s).', command, handler.maxOutputs);
    end

    outputs = handler.run(commandArgs);
    if ~iscell(outputs)
        error(errorId(appName, 'InvalidTestRequest'), ...
            'Command %s handler must return a cell array of outputs.', command);
    end
    if numel(outputs) < nout
        error(errorId(appName, 'InvalidTestRequest'), ...
            'Command %s returned fewer outputs than requested.', command);
    end
    outputs = outputs(1:nout);
end

function validateHandlers(appName, handlers)
    required = {'command', 'minArgs', 'maxArgs', 'maxOutputs', 'run'};
    for k = 1:numel(required)
        if ~isfield(handlers, required{k})
            error(errorId(appName, 'InvalidTestRequest'), ...
                'App test handler is missing field "%s".', required{k});
        end
    end
end

function id = errorId(appName, suffix)
    id = sprintf('%s:%s', appName, suffix);
end
