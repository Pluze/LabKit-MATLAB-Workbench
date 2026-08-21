function node = workspace(varargin)
%WORKSPACE Define the App's central working area and optional pages.
%
% Usage:
%   node = labkit.app.layout.workspace()
%   node = labkit.app.layout.workspace(content, Name=Value)
%
% Description:
%   Declares a single-content workspace or a workspace extended with
%   node.page(id,title,content) and node.initialPage(id). A named page accepts
%   one workspace node or a nonempty row cell array of nodes arranged
%   vertically; growable tables and plots share the available page height.
%
% Inputs:
%   content - Optional plotArea, dataTable, group, or section node.
%       For node.page, content may also be a nonempty row cell array of
%       workspace nodes.
%
% Options:
%   Title - Reader-facing workspace title. Default: "Workspace".
%
% Outputs:
%   node - Immutable workspace node accepted by layout.workbench.
%
% Errors:
%   Throws labkit:app:contract:* for invalid content, pages, or callbacks.
%
% Typical Call:
%   node = labkit.app.layout.workspace(plotArea);
%
% See also labkit.app.layout.workbench,
%   labkit.app.layout.plotArea
node = labkit.app.internal.contract.LayoutNode.workspace(varargin{:});
end
