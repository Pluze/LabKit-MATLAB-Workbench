%GROUPNODES Create one semantic group without changing member coordinates.
function [document, groupId] = groupNodes(document, nodeIds, name)
nodeIds = unique(string(nodeIds(:)), "stable");
indices = nodeIndices(document, nodeIds);
if isempty(indices)
    error("figure_studio:figureDocument:EmptyGroup", ...
        "Select at least one object to create a group.");
end
panelIds = unique(string({document.nodes(indices).panelId}));
if numel(panelIds) ~= 1
    error("figure_studio:figureDocument:CrossPanelGroup", ...
        "A semantic group cannot span multiple panels.");
end
groupId = nextGroupId(document);
if nargin < 3 || strlength(string(name)) == 0
    name = "Group " + extractAfter(groupId, "group-");
end
group = groupTemplate(groupId, panelIds, string(name));
document.nodes(end + 1, 1) = group;
for index = reshape(indices, 1, [])
    document.nodes(index).groupId = groupId;
    document.nodes(index).parentId = groupId;
end
document.revision = document.revision + 1;
end

function indices = nodeIndices(document, ids)
[found, indices] = ismember(ids, string({document.nodes.id}));
if ~all(found)
    error("figure_studio:figureDocument:UnknownNode", ...
        "One or more selected figure nodes do not exist.");
end
indices = indices(:);
indices(string({document.nodes(indices).kind}) == "group") = [];
end

function id = nextGroupId(document)
number = 1;
ids = string({document.nodes.id});
id = "group-" + string(number);
while any(ids == id)
    number = number + 1;
    id = "group-" + string(number);
end
end

function node = groupTemplate(id, panelId, name)
node = struct("id", id, "panelId", panelId, "parentId", "", ...
    "groupId", "", "kind", "group", "role", "group", ...
    "name", name, "visible", true, "locked", false, ...
    "dataLocked", true, "legendVisible", false, ...
    "data", struct(), "sourceStyle", struct(), "overrides", struct(), ...
    "metadata", struct("compound", true));
end
