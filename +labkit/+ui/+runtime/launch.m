function varargout = launch(definitionFcn, requirementsFcn, versionFcn, varargin)
%LAUNCH Dispatch requests and launch a LabKit runtime definition.
%
% App-facing contract:
%   fig = labkit.ui.runtime.launch(definitionFcn, requirementsFcn, ...
%       versionFcn, varargin{:})
%   [fig, debug] = labkit.ui.runtime.launch(..., "debug")
%   requirements = labkit.ui.runtime.launch(..., "requirements")
%   version = labkit.ui.runtime.launch(..., "version")
%   fig = labkit.ui.runtime.launch(..., "RequestAdapter", adapter, args{:})
%
% Inputs:
%   definitionFcn - function handle returning a Runtime V2 definition.
%   requirementsFcn - function handle returning labkit.requirements metadata.
%   versionFcn - function handle returning app version metadata.
%   varargin - normal, debug, requirements, or version request arguments.
%       An advanced app with a typed launch handoff may prefix its arguments
%       with `"RequestAdapter", adapter`; adapter receives the remaining cell
%       array and returns `[runtimeRequest, dispatchArgs]`. The request must be
%       a scalar struct and remains outside canonical app state.
%
% Outputs:
%   Normal launch returns the app figure. Debug launch may also return the
%   debug context. Lightweight requests return their requested metadata.

    assertFactory(definitionFcn, "definitionFcn");
    assertFactory(requirementsFcn, "requirementsFcn");
    assertFactory(versionFcn, "versionFcn");
    requirements = requirementsFcn();
    info = versionFcn();
    appName = char(string(info.name));
    [request, dispatchArgs] = prepareRequest(varargin);
    [handled, outputs, debug] = dispatchRequest( ...
        appName, dispatchArgs, nargout, "Requirements", requirements, ...
        "Version", info);
    if handled
        varargout = outputs;
        return;
    end
    validateOutputCount(appName, debug, nargout);
    request.debug = debug;
    fig = runAppDefinition(definitionFcn(), request);
    applyVersionTitle(fig, info);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debug;
    end
end

function [request, dispatchArgs] = prepareRequest(args)
    request = struct();
    dispatchArgs = args;
    if numel(args) < 2 || ~isScalarText(args{1}) || ...
            string(args{1}) ~= "RequestAdapter"
        return;
    end
    adapter = args{2};
    if ~isa(adapter, 'function_handle')
        error('labkit:ui:runtime:InvalidRequestAdapter', ...
            'RequestAdapter must be a function handle.');
    end
    [request, dispatchArgs] = adapter(args(3:end));
    if ~isstruct(request) || ~isscalar(request) || ~iscell(dispatchArgs)
        error('labkit:ui:runtime:InvalidRequestAdapter', ...
            ['RequestAdapter must return a scalar request struct and a ' ...
            'dispatch-argument cell array.']);
    end
end

function tf = isScalarText(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function assertFactory(value, name)
    if ~isa(value, 'function_handle')
        error('labkit:ui:runtime:InvalidLaunchFactory', ...
            '%s must be a function handle.', name);
    end
end

function validateOutputCount(appName, debug, nout)
    if isstruct(debug) && isfield(debug, 'enabled') && logical(debug.enabled)
        maximum = 2;
    else
        maximum = 1;
    end
    if nout > maximum
        error([appName ':TooManyOutputs'], ...
            '%s returns at most %d output(s) for this request.', ...
            appName, maximum);
    end
end
