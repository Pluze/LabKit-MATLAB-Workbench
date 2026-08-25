%PRESENT Build the flat layer projection and cascade editor state.
function view = present(editor, hasFigure)
[data, rowNames, nodeIds] = layerData(editor.document);
selectedRows = find(ismember(nodeIds, editor.document.selection));
selection = [selectedRows(:), ones(numel(selectedRows), 1)];
summary = selectionSummary(editor.document, editor.document.selection);
view = labkit.app.view.Snapshot() ...
    .text("objectSelectionSummary", summary) ...
    .tableData("objectTable", data, ...
        Columns=["Show", "Lock", "Legend", "Type", "Role", "Name", ...
            "Group", "Axis"], ...
        RowNames=rowNames) ...
    .tableCellSelection("objectTable", ...
        labkit.app.event.TableCellSelection(selection)) ...
    .value("objectStyleScope", editor.activeScope) ...
    .value("objectStyleProperty", editor.activeProperty) ...
    .value("objectStyleValue", editor.propertyDraft) ...
    .value("objectMoveX", editor.transformDraft.dx) ...
    .value("objectMoveY", editor.transformDraft.dy) ...
    .value("objectScaleX", editor.transformDraft.sx) ...
    .value("objectScaleY", editor.transformDraft.sy);
ids = ["objectTable", "objectStyleScope", "objectStyleProperty", ...
    "objectStyleValue", "applyObjectStyle", "resetObjectStyle"];
for id = ids
    view = view.enabled(id, hasFigure);
end
hasSelection = hasFigure && ~isempty(editor.document.selection);
for id = ["groupObjects", "ungroupObjects", "duplicateObjects", ...
        "objectsToFront", "objectsForward", "objectsBackward", "objectsToBack"]
    view = view.enabled(id, hasSelection);
end
hasEditable = hasFigure && editableSelection(editor.document);
for id = ["objectMoveX", "objectMoveY", "objectScaleX", ...
        "objectScaleY", "applyObjectTransform", "alignObjectsLeft", ...
        "alignObjectsCenter", "alignObjectsRight", "alignObjectsBottom", ...
        "alignObjectsMiddle", "alignObjectsTop", "distributeObjectsH", ...
        "distributeObjectsV"]
    view = view.enabled(id, hasEditable);
end
end

function tf = editableSelection(document)
tf = false;
selected = document.selection;
while ~isempty(selected)
    indices = find(ismember(string({document.nodes.id}), selected));
    if any(~[document.nodes(indices).dataLocked]), tf = true; return; end
    selected = string({document.nodes(ismember( ...
        string({document.nodes.parentId}), selected)).id}).';
end
end

function [data, rowNames, ids] = layerData(document)
nodes = document.nodes;
data = cell(numel(nodes), 8);
rowNames = strings(1, numel(nodes));
ids = strings(numel(nodes), 1);
for k = 1:numel(nodes)
    node = nodes(k);
    prefix = "";
    if node.kind ~= "group" && strlength(node.groupId) > 0
        prefix = "  ↳ ";
    end
    data{k, 1} = logical(node.visible);
    data{k, 2} = logical(node.locked);
    data{k, 3} = logical(node.legendVisible);
    data{k, 4} = char(node.kind);
    data{k, 5} = char(node.role);
    data{k, 6} = char(prefix + node.name);
    data{k, 7} = char(node.groupId);
    data{k, 8} = char(axisSide(node));
    rowNames(k) = string(k);
    ids(k) = node.id;
end

function value = axisSide(node)
value = "left";
if isfield(node.metadata, "yAxisSide")
    value = string(node.metadata.yAxisSide);
end
end
end

function value = selectionSummary(document, selected)
selected = string(selected(:));
if isempty(selected)
    value = "No objects selected";
    return;
end
nodes = document.nodes(ismember(string({document.nodes.id}), selected));
kinds = unique(string({nodes.kind}));
roles = unique(string({nodes.role}));
value = string(numel(nodes)) + " selected | type " + join(kinds, ", ") + ...
    " | role " + join(roles, ", ");
end
