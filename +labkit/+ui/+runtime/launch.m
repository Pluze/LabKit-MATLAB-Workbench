function varargout = launch(definitionFcn, requirementsFcn, versionFcn, varargin)
%LAUNCH Dispatch requests and launch a LabKit runtime definition.
%
% App-facing contract:
%   fig = labkit.ui.runtime.launch(definitionFcn, requirementsFcn, ...
%       versionFcn, varargin{:})
%   [fig, debug] = labkit.ui.runtime.launch(..., "debug")
%   requirements = labkit.ui.runtime.launch(..., "requirements")
%   version = labkit.ui.runtime.launch(..., "version")
%
% Inputs:
%   definitionFcn - function handle returning a v1 or v2 runtime definition.
%   requirementsFcn - function handle returning labkit.requirements metadata.
%   versionFcn - function handle returning app version metadata.
%   varargin - normal, debug, requirements, or version request arguments.
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
    [handled, outputs, debug] = labkit.ui.runtime.dispatchRequest( ...
        appName, varargin, nargout, "Requirements", requirements, ...
        "Version", info);
    if handled
        varargout = outputs;
        return;
    end
    validateOutputCount(appName, debug, nargout);
    fig = labkit.ui.runtime.run(definitionFcn(), struct("debug", debug));
    labkit.ui.runtime.applyVersionTitle(fig, info);
    if nargout >= 1
        varargout{1} = fig;
    end
    if nargout >= 2
        varargout{2} = debug;
    end
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
