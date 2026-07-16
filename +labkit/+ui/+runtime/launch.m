function varargout = launch(definitionFcn, requirementsFcn, versionFcn, varargin)
%LAUNCH Dispatch requests and launch a LabKit runtime definition.
%
% Usage:
%   fig = labkit.ui.runtime.launch(definitionFcn, requirementsFcn, ...
%       versionFcn, varargin{:})
%   [fig, debug] = labkit.ui.runtime.launch(..., "debug")
%   requirements = labkit.ui.runtime.launch(..., "requirements")
%   version = labkit.ui.runtime.launch(..., "version")
%   fig = labkit.ui.runtime.launch(..., "RequestAdapter", adapter, args{:})
%
% Inputs:
%   definitionFcn - Function handle returning a definition created by define.
%   requirementsFcn - Function handle returning the app's requirements struct.
%   versionFcn - Function handle returning app version metadata with a name
%       field used for titles and app-specific error identifiers.
%
% Outputs:
%   fig - App figure for normal and debug launches.
%   debug - Debug context returned only when the request is "debug".
%   requirements - Requirements metadata for a "requirements" request.
%   version - Version metadata for a "version" request.
%
% Description:
%   launch checks product requirements, creates project and session state,
%   builds the layout, presents the first view, and then queues the definition's
%   Start action. The startup window reports these phases until the app is
%   ready. A debug launch additionally enables tracing and queues DebugSample.
%   The "requirements" and "version" requests return metadata without building
%   a GUI.
%
% Request Adapter:
%   Apps that accept typed entry-point arguments can pass "RequestAdapter",
%   adapter before those arguments. MATLAB calls
%   [request,dispatchArgs] = adapter(args), where args is a cell array. request
%   must be a scalar struct and is available to actions as services.request;
%   dispatchArgs must be a cell array containing a normal runtime request such
%   as {} or {"debug"}.
%
% Typical Call:
%   fig = labkit.ui.runtime.launch(@appDefinition, @requirements, @version);
%
% See also labkit.ui.runtime.define

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
