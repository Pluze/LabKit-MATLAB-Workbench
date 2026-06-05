function [handled, outputs, debugContext] = dispatchRequest(appName, args, nout)
%DISPATCHREQUEST Dispatch app debug launch requests.
%
% Usage:
%   [handled, outputs, debug] = labkit.ui.app.dispatchRequest( ...
%       "labkit_Example_app", varargin, nargout);
%
% Inputs:
%   appName - app entry-point name used to build app-scoped error IDs.
%   args - input argument cell from the app entry point.
%   nout - requested output count from the app entry point.
%
% Outputs:
%   handled - false for normal and debug launches.
%   outputs - empty cell array reserved for future launch request handlers.
%   debugContext - disabled for normal launches; enabled for "debug",
%       "-debug", "--debug", or "__labkit_debug__" launches. Debug launch
%       requests do not consume app launch.

    appName = char(appName);
    handled = false;
    outputs = {};
    debugContext = labkit.ui.diag.createContext(appName, struct('enabled', false));

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
        debugContext = labkit.ui.diag.createContext(appName, opts);
        return;
    end

    error(errorId(appName, 'UnsupportedInput'), ...
        '%s does not accept input arguments.', appName);
end

function tf = isDebugRequest(request)
    tf = any(request == ["__labkit_debug__", "debug", "-debug", "--debug"]);
end

function opts = debugOptions(appName, request, args)
    opts = struct();
    if numel(args) > 2
        error(errorId(appName, 'InvalidDebugOptions'), ...
            '%s accepts at most one options struct.', char(request));
    elseif numel(args) == 2
        opts = args{2};
    end
    if ~isstruct(opts)
        error(errorId(appName, 'InvalidDebugOptions'), ...
            '%s options must be a struct.', char(request));
    end
    opts.enabled = true;
    if ~isfield(opts, 'traceEnabled')
        opts.traceEnabled = true;
    end
end

function id = errorId(appName, suffix)
    id = sprintf('%s:%s', appName, suffix);
end
