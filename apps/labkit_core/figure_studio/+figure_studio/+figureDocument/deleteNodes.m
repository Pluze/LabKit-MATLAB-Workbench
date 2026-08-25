%DELETENODES Delete selected editable nodes and compound descendants.
function document = deleteNodes(document, ids)
ids = string(ids(:));
if isempty(ids), return; end
changed = true;
while changed
    descendants = string({document.nodes.parentId}).';
    newIds = string({document.nodes(ismember(descendants, ids)).id}).';
    combined = unique([ids; newIds]);
    changed = numel(combined) > numel(ids);
    ids = combined;
end
keep = ~ismember(string({document.nodes.id}), ids);
document.nodes = document.nodes(keep);
document.selection = setdiff(document.selection, ids, 'stable');
end
