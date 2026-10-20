function node = group(id, children, varargin)
%GROUP Arrange related child elements without a titled boundary.
%
% Usage:
%   node = labkit.app.layout.group(id, children, Name=Value)
%
% Description:
%   Groups controls, sections, plots, or tables into one semantic arrangement.
%   A group containing a plot or table can grow with its workspace page.
%   A titled group draws a nested reader-facing boundary.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%   children - Row cell array of layout nodes.
%
% Options:
%   Layout - "auto", "vertical", or "horizontal". Default: "auto".
%   Title - Reader-facing nested-group title or blank. Default: blank.
%   ColumnWidths - For horizontal Layout only, a row cell array with one
%       entry per child: positive pixel width, "fit", or "1x". Default: {},
%       giving every child an equal flexible width.
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
node = labkit.app.internal.contract.LayoutNode.group(id, children, varargin{:});
end
