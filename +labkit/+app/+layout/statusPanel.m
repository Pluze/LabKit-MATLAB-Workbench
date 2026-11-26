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
%   Presentation - "text" (scrollable text) or "label" (short summary), or "note" (inline explanatory text).
%   Title - Heading for the message. The default "Status" uses the section
%       heading when available.
%   Text - Static text lines. When omitted, the runtime's latest status is
%       displayed. Default: strings(1,0).
%   Lines - Preferred capacity for longer messages. Text panels grow with wrapped
%       content up to the larger of six lines or this hint, then scroll.
%       Integer from 1 through 12. Default: 5.
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
% See also labkit.app.CallbackContext
node = labkit.app.internal.contract.LayoutNode.statusPanel(id, varargin{:});
end
