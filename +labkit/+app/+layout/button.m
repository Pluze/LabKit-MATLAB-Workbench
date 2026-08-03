function node = button(id, label, onPressed, varargin)
%BUTTON Add a push button with one explicit pressed callback.
%
% Usage:
%   node = labkit.app.layout.button(id, label, onPressed, Name=Value)
%
% Description:
%   Declares a semantic push button without creating a native component.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%   label - Nonempty text displayed on the button.
%   onPressed - Scalar function handle with the fixed callback
%       state = onPressed(state,context).
%
% Options:
%   BusyMessage - Reader-facing stage text shown when the action remains
%       active beyond the Runtime's brief busy-display delay. Empty text uses
%       the button label. Runtime blocks new input immediately, freezes native
%       controls when feedback becomes visible, and restores the committed
%       view when the transaction ends. Default: "".
%   Enabled - Initial logical enabled state. Default: true.
%   Tooltip - Nonempty hover text explaining the action's scientific or
%       workflow effect. Default: label.
%
% Outputs:
%   node - Immutable internal layout node accepted by layout containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, options, or handlers.
%
% Typical Call:
%   node = labkit.app.layout.button("run", "Run", @runAnalysis, ...
%       Tooltip="Compute the current analysis from the selected inputs.");
%
% See also labkit.app.layout.workbench, labkit.app.CallbackContext
node = labkit.app.internal.LayoutNode.button( ...
    id, label, onPressed, varargin{:});
end
