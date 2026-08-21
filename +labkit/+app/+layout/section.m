function node = section(id, title, children)
%SECTION Arrange related child elements under a visible title.
%
% Usage:
%   node = labkit.app.layout.section(id, title, children)
%
% Description:
%   Groups compatible controls under a reader-facing title.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%   title - Nonempty section title.
%   children - Row cell array of layout nodes.
%
% Outputs:
%   node - Immutable internal layout node accepted by containers.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, children, or options.
%
% Typical Call:
%   node = labkit.app.layout.section("inputs", "Inputs", {gainField});
%
% See also labkit.app.layout.group, labkit.app.layout.tab
node = labkit.app.internal.contract.LayoutNode.section(id, title, children);
end
