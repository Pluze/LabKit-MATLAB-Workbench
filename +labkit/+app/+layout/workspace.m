function node = workspace(varargin)
%WORKSPACE Define the App's central working area and optional pages.
%
% Usage:
%   node = labkit.app.layout.workspace()
%   node = labkit.app.layout.workspace(content, Name=Value)
%
% Description:
%   Declares a single-content workspace or a workspace extended with
%   node.page(id,title,content) and node.initialPage(id).
%
% Inputs:
%   content - Optional plotArea, dataTable, group, or section node.
%
% Options:
%   PageChanged - StateHandler with Event="valueChange". Default: [].
%
% Outputs:
%   node - Immutable workspace node accepted by layout.workbench.
%
% Errors:
%   Throws labkit:app:contract:* for invalid content, pages, or handlers.
%
% Typical Call:
%   node = labkit.app.layout.workspace(plotArea);
%
% See also labkit.app.layout.workbench,
%   labkit.app.layout.plotArea
node = labkit.app.internal.LayoutNode.workspace(varargin{:});
end
