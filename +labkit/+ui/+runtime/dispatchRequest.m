function [handled, outputs, debugContext] = dispatchRequest(appName, args, nout, varargin)
%DISPATCHREQUEST Dispatch app launch requests and contract checks.
%
% Usage:
%   [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
%       "labkit_Example_app", varargin, nargout);
%   [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
%       "labkit_Example_app", varargin, nargout, "Requirements", req);
%   [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
%       "labkit_Example_app", varargin, nargout, ...
%       "Requirements", req, "Version", info);
%
% Inputs:
%   appName - app entry-point name used to build app-scoped error IDs.
%   args - input argument cell from the app entry point.
%   nout - requested output count from the app entry point.
%   Name-value options:
%       Requirements - optional struct returned by app requirements().
%       Version - optional struct returned by app version().
%
% Outputs:
%   handled - true only when a lightweight request such as "requirements" or
%       "version" is consumed; false for normal and debug launches.
%   outputs - one-cell output containing the requested app struct for handled
%       lightweight requests; empty otherwise.
%   debugContext - disabled for normal launches; enabled for "debug" launches.
%       Debug launch requests do not consume app launch. Public app debug
%       launches write a trace log under artifacts/debug so the last event is
%       still available if the GUI freezes before the Log tab can be inspected.

    appName = char(appName);
    options = parseOptions(varargin{:});
    handled = false;
    outputs = {};
    debugContext = labkit.ui.debug.context(appName, struct('enabled', false));

    if isempty(args)
        assertCompatible(appName, options.Requirements);
        return;
    end
    if ~(ischar(args{1}) || (isstring(args{1}) && isscalar(args{1})))
        error(errorId(appName, 'UnsupportedInput'), ...
            '%s does not accept input arguments.', appName);
    end

    request = string(args{1});
    if request == "requirements"
        if nout > 1
            error(errorId(appName, 'TooManyOutputs'), ...
                '%s requirements request returns at most one output.', appName);
        end
        if numel(args) > 1
            error(errorId(appName, 'UnsupportedInput'), ...
                '%s requirements request does not accept options.', appName);
        end
        handled = true;
        outputs = {options.Requirements};
        return;
    end

    if request == "version"
        if nout > 1
            error(errorId(appName, 'TooManyOutputs'), ...
                '%s version request returns at most one output.', appName);
        end
        if numel(args) > 1
            error(errorId(appName, 'UnsupportedInput'), ...
                '%s version request does not accept options.', appName);
        end
        handled = true;
        outputs = {options.Version};
        return;
    end

    if isDebugRequest(request)
        if nout > 2
            error(errorId(appName, 'TooManyOutputs'), ...
                '%s debug mode returns at most the app figure and debug log.', appName);
        end
        if numel(args) > 1
            error(errorId(appName, 'UnsupportedInput'), ...
                '%s debug launch does not accept options.', appName);
        end
        assertCompatible(appName, options.Requirements);
        debugContext = labkit.ui.debug.context(appName, struct( ...
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

function options = parseOptions(varargin)
    options = struct('Requirements', [], 'Version', []);
    if isempty(varargin)
        return;
    end
    if mod(numel(varargin), 2) ~= 0
        error('labkit:ui:runtime:InvalidDispatchOptions', ...
            'Dispatch options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        name = string(varargin{k});
        switch name
            case "Requirements"
                options.Requirements = varargin{k + 1};
            case "Version"
                options.Version = varargin{k + 1};
            otherwise
                error('labkit:ui:runtime:InvalidDispatchOptions', ...
                    'Unsupported dispatch option "%s".', name);
        end
    end
end

function assertCompatible(appName, requirements)
    if ~isempty(requirements)
        labkit.contract.assertRequirements(appName, requirements);
    end
end

function id = errorId(appName, suffix)
    id = sprintf('%s:%s', appName, suffix);
end
