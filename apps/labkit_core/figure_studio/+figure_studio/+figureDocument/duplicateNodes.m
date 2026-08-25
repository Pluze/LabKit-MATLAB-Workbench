%DUPLICATENODES Duplicate selected presentation nodes with data still locked.
function [document, newIds] = duplicateNodes(document, nodeIds)
nodeIds = unique(string(nodeIds(:)), "stable");
[found, indices] = ismember(nodeIds, string({document.nodes.id}));
if ~all(found)
    error("figure_studio:figureDocument:UnknownNode", ...
        "One or more selected figure nodes do not exist.");
end
indices(string({document.nodes(indices).kind}) == "group") = [];
newIds = strings(numel(indices), 1);
for k = 1:numel(indices)
    node = document.nodes(indices(k));
    node.id = nextObjectId(document);
    node.name = node.name + " copy";
    node.parentId = "";
    node.groupId = "";
    node.metadata.duplicatedFrom = document.nodes(indices(k)).id;
    document.nodes(end + 1, 1) = node;
    newIds(k) = node.id;
end
document.selection = newIds;
document.revision = document.revision + 1;
end

function id = nextObjectId(document)
number = numel(document.nodes) + 1;
ids = string({document.nodes.id});
id = "object-" + string(number);
while any(ids == id)
    number = number + 1;
    id = "object-" + string(number);
end
end
