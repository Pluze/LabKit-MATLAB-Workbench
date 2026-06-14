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
%   debugContext - disabled for normal launches; enabled for "debug" launches.
%       Debug launch requests do not consume app launch. Public app debug
%       launches write a trace log under artifacts/debug so the last event is
%       still available if the GUI freezes before the Log tab can be inspected.

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
        if numel(args) > 1
            error(errorId(appName, 'UnsupportedInput'), ...
                '%s debug launch does not accept options.', appName);
        end
        debugContext = labkit.ui.diag.createContext(appName, struct( ...
            'enabled', true, ...
            'logFile', defaultDebugLogFile(appName)));
        return;
    end

    error(errorId(appName, 'UnsupportedInput'), ...
        '%s does not accept input arguments.', appName);
end

function tf = isDebugRequest(request)
    tf = request == "debug";
end

function id = errorId(appName, suffix)
    id = sprintf('%s:%s', appName, suffix);
end
