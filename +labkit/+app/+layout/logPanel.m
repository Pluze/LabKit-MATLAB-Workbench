function node = logPanel(id, varargin)
%LOGPANEL Add a text display for App log messages.
%
% Usage:
%   node = labkit.app.layout.logPanel(id, Name=Value)
%
% Description:
%   Declares a runtime-populated multiline App log display.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   Title - Visible panel title. Default: "Log".
%
% Outputs:
%   node - Immutable internal layout node accepted by containers.
%
% Errors:
%   Throws labkit:app:contract:InvalidValue for an invalid ID.
%
% Typical Call:
%   node = labkit.app.layout.logPanel("appLog");
%
% See also labkit.app.layout.statusPanel,
%   labkit.app.CallbackContext
node = labkit.app.internal.LayoutNode.logPanel(id, varargin{:});
end
