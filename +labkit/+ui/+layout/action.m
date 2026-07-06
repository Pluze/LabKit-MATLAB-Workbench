function layout = action(id, labelText, onInvoke, varargin)
%ACTION Create an app-command layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.action(id, label, onInvoke, opts...)
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
%   layout - scalar data-only UI layout struct.

    if nargin < 3
        onInvoke = [];
    end
    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.onInvoke = onInvoke;
    layout = makeLayoutNode('action', id, props, {}, struct());
end
