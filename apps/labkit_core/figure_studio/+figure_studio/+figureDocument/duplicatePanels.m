%DUPLICATEPANELS Duplicate panels with all presentation nodes.
function [document, newIds] = duplicatePanels(document, panelIds)
panelIds = string(panelIds(:));
newIds = strings(numel(panelIds), 1);
newCount = 0;
for sourceId = reshape(panelIds, 1, [])
    sourceIndex = find(string({document.panels.id}) == sourceId, 1);
    if isempty(sourceIndex), continue; end
    panel = document.panels(sourceIndex);
    newId = nextPanelId(document);
    panel.id = newId;
    panel.name = panel.name + " copy";
    panel.geometry(1:2) = min(panel.geometry(1:2) + 0.04, ...
        1 - panel.geometry(3:4));
    document.panels(end + 1, 1) = panel;
    sourceNodes = document.nodes(string({document.nodes.panelId}) == sourceId);
    idMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
    for k = 1:numel(sourceNodes)
        oldId = sourceNodes(k).id;
        sourceNodes(k).id = nextObjectId(document, k);
        sourceNodes(k).panelId = newId;
        idMap(char(oldId)) = char(sourceNodes(k).id);
    end
    for k = 1:numel(sourceNodes)
        for field = ["parentId", "groupId"]
            old = sourceNodes(k).(char(field));
            if strlength(old) > 0 && isKey(idMap, char(old))
                sourceNodes(k).(char(field)) = string(idMap(char(old)));
            end
        end
    end
    document.nodes = [document.nodes; sourceNodes(:)];
    newCount = newCount + 1;
    newIds(newCount, 1) = newId;
end
newIds = newIds(1:newCount);
end

function id = nextPanelId(document)
id = "panel-" + string(nextNumber(string({document.panels.id})));
end

function id = nextObjectId(document, offset)
id = "object-" + string(nextNumber(string({document.nodes.id})) + offset - 1);
end

function result = nextNumber(ids)
values = zeros(numel(ids), 1);
for k = 1:numel(ids)
    token = regexp(char(ids(k)), '(\d+)$', 'tokens', 'once');
    if ~isempty(token), values(k) = str2double(token{1}); end
end
result = max([values; 0]) + 1;
end
