function node = workbench(children, varargin)
%WORKBENCH Assemble controls and a central workspace into the root layout.
%
% Usage:
%   node = labkit.app.layout.workbench(children, Name=Value)
%
% Description:
%   Produces the root semantic layout required by labkit.app.Definition.
%
% Inputs:
%   children - Row cell array of controls, groups, sections, or tabs.
%
% Options:
%   Workspace - Value returned by layout.workspace. Default: [].
%
% Outputs:
%   node - Immutable root layout node.
%
% Errors:
%   Throws labkit:app:contract:* for invalid children or workspace values.
%
% Typical Call:
%   node = labkit.app.layout.workbench({runButton});
%
% See also labkit.app.Definition,
%   labkit.app.layout.workspace
node = labkit.app.internal.LayoutNode.workbench(children, varargin{:});
end
