function spec = action(id, labelText, onInvoke, varargin)
%ACTION Create an app-command spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.action(id, label, onInvoke, opts...)
%
% Inputs:
%   id - globally unique action id.
%   labelText - command label.
%   onInvoke - function handle called as callback(control, event).
%   enabled, priority, tooltip - optional app-neutral props.
%   busyMessage - optional string. Overrides the default busy title text,
%       which is the action label.
%
% Output:
%   spec - scalar data-only UI spec struct.

    if nargin < 3
        onInvoke = [];
    end
    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.onInvoke = onInvoke;
    spec = makeSpec('action', id, props, {}, struct());
end
