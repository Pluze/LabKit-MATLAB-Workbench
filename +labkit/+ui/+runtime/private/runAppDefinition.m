% Private UI runtime helper. Launches a validated Runtime V2 definition.
function fig = runAppDefinition(def, request)
%
% App-facing contract:
%   fig = labkit.ui.runtime.run(def)
%   fig = labkit.ui.runtime.run(def, request)
%
% Inputs:
%   def - scalar struct returned by labkit.ui.runtime.define.
%   request - optional struct. The `debug` field may contain a LabKit debug
%       context created by labkit.ui.runtime.dispatchRequest. Other app-specific
%       fields are forwarded read-only to action handlers as services.request.
%
% Output:
%   fig - created app figure.
%
% Runtime behavior:
%   The framework validates the V2 definition and owns project/session
%   creation, queued actions, presentation, resources, persistence, and Start.

    if nargin < 2
        request = struct();
    end
    validateAppDefinition(def);
    fig = runV2App(def, request);
end
