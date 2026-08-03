function node = tab(id, title, children)
%TAB Add a named tab containing related child elements.
%
% Usage:
%   node = labkit.app.layout.tab(id, title, children)
%
% Description:
%   Declares one named control-side tab.
%
% Inputs:
%   id - Unique MATLAB identifier for the layout target.
%   title - Nonempty tab title.
%   children - Row cell array of compatible layout nodes.
%
% Outputs:
%   node - Immutable internal layout node accepted by workbench.
%
% Errors:
%   Throws labkit:app:contract:* for invalid IDs, titles, or children.
%
% Typical Call:
%   node = labkit.app.layout.tab("settings", "Settings", {gainField});
%
% See also labkit.app.layout.section, labkit.app.layout.workbench
node = labkit.app.internal.contract.LayoutNode.tab(id, title, children);
end
