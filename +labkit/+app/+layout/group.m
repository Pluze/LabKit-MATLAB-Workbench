function node = group(id, children, varargin)
%GROUP Arrange related child elements without a titled boundary.
%
% Usage:
%   node = labkit.app.layout.group(id, children, Name=Value)
%
% Description:
%   Groups compatible control nodes into one semantic arrangement.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%   children - Row cell array of layout nodes.
%
% Options:
%   Layout - "auto", "vertical", or "horizontal". Default: "auto".
%
% Outputs:
%   node - Immutable internal layout node accepted by containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, children, or options.
%
% Typical Call:
%   node = labkit.app.layout.group("inputs", {gainField});
%
% See also labkit.app.layout.section, labkit.app.layout.workbench
node = labkit.app.internal.LayoutNode.group(id, children, varargin{:});
end
