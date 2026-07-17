function layout = action(id, labelText, onInvoke, varargin)
%ACTION Create an app-command layout node.
%
% Usage:
%   layout = labkit.ui.layout.action(id, labelText, onInvoke)
%   layout = labkit.ui.layout.action(id, labelText, onInvoke, Name=Value)
%
% Inputs:
%   id - Text scalar used to identify the action. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   labelText - Text displayed on the push button.
%   onInvoke - Function handle called as onInvoke(control,event) after the
%       button is pressed. Use [] when a runtime binding will supply behavior.
%       The default is [].
%
% Name-Value Arguments:
%   enabled - Logical value controlling whether the button can be pressed.
%       Default: true.
%   busyMessage - Text appended to the app title while onInvoke runs. Default:
%       labelText.
%
% Outputs:
%   layout - Scalar action node with kind, id, props, children, and slots
%       fields. The node creates no graphics until the workbench is launched.
%
% Description:
%   action represents one app command. A section may contain an action directly,
%   or several actions may be placed in an action group. The runtime ignores a
%   press while the figure is already busy and restores the normal title after
%   the callback completes or throws.
%
% Errors:
%   labkit:ui:layout:InvalidId - id is not a valid MATLAB field name.
%   labkit:ui:layout:InvalidOptions or InvalidOptionName - Name-value
%   arguments are unpaired or an option name is not valid scalar text.
%   Callback value compatibility is checked when the runtime builds the node.
%
% Example:
%   runAction = labkit.ui.layout.action( ...
%       "runAnalysis", "Run analysis", @(~,~) disp("Running"));
%   assert(runAction.kind == "action")
%
% See also labkit.ui.layout.group, labkit.ui.layout.section

    if nargin < 3
        onInvoke = [];
    end
    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.onInvoke = onInvoke;
    layout = makeLayoutNode('action', id, props, {}, struct());
end
