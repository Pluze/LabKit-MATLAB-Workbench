function node = statusPanel(id, varargin)
%STATUSPANEL Add a text display for current App status.
%
% Usage:
%   node = labkit.app.layout.statusPanel(id, Name=Value)
%
% Description:
%   Declares a current-status or static instruction display.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%
% Options:
%   Title - Visible panel title. Default: "Status".
%   Text - Static text lines. When omitted, the runtime's latest status is
%       displayed. Default: strings(1,0).
%
% Outputs:
%   node - Immutable internal layout node accepted by containers.
%
% Errors:
%   Throws labkit:app:contract:InvalidValue for an invalid ID.
%
% Typical Call:
%   node = labkit.app.layout.statusPanel("status");
%
% See also labkit.app.layout.logPanel,
%   labkit.app.CallbackContext
node = labkit.app.internal.LayoutNode.statusPanel(id, varargin{:});
end
