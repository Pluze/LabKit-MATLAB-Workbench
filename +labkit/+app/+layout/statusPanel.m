function node = statusPanel(id)
%STATUSPANEL Add a text display for current App status.
%
% Usage:
%   node = labkit.app.layout.statusPanel(id)
%
% Description:
%   Declares a runtime-populated current-status display.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
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
node = labkit.app.internal.LayoutNode.statusPanel(id);
end
