function [handled, outputs, debugLog] = handleAppRequest(appName, args, nout, handlers)
%HANDLEAPPREQUEST Deprecated wrapper for dispatchAppRequest.
%
% Usage:
%   [handled, outputs, debugLog] = labkit.ui.handleAppRequest( ...
%       appName, varargin, nargout, handlers);
%
% This compatibility surface is retained for one migration cycle. New app
% code should call labkit.ui.dispatchAppRequest.

    if nargin < 4
        handlers = struct('command', {}, 'minArgs', {}, ...
            'maxArgs', {}, 'maxOutputs', {}, 'run', {});
    end
    [handled, outputs, debugLog] = labkit.ui.dispatchAppRequest( ...
        appName, args, nout, handlers);
end
