function node = button(id, label, handler, varargin)
%BUTTON Add a push button that dispatches an action handler.
%
% Usage:
%   node = labkit.app.layout.button(id, label, handler, Name=Value)
%
% Description:
%   Declares a semantic push button without creating a native component.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%   label - Nonempty text displayed on the button.
%   handler - StateHandler whose Event is "action".
%
% Options:
%   BusyMessage - Status text while the action runs. Default: "".
%   Enabled - Initial logical enabled state. Default: true.
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, options, or handlers.
%
% Typical Call:
%   node = labkit.app.layout.button("run", "Run", runHandler);
%
% See also labkit.app.StateHandler, labkit.app.layout.workbench
node = labkit.app.internal.LayoutNode.button(id, label, handler, varargin{:});
end
