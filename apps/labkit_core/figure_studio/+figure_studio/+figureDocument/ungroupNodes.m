%UNGROUPNODES Remove semantic group membership from selected object nodes.
function document = ungroupNodes(document, nodeIds)
nodeIds = unique(string(nodeIds(:)));
[found, indices] = ismember(nodeIds, string({document.nodes.id}));
if ~all(found)
    error("figure_studio:figureDocument:UnknownNode", ...
        "One or more selected figure nodes do not exist.");
end
groupIds = unique(string({document.nodes(indices).groupId}));
groupIds(groupIds == "") = [];
for index = reshape(indices, 1, [])
    document.nodes(index).groupId = "";
    document.nodes(index).parentId = "";
end
for groupId = reshape(groupIds, 1, [])
    stillUsed = any(string({document.nodes.groupId}) == groupId);
    if ~stillUsed
        document.nodes(string({document.nodes.id}) == groupId) = [];
    end
end
document.revision = document.revision + 1;
end
