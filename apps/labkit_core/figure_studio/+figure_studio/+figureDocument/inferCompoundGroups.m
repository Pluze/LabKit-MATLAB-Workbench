%INFERCOMPOUNDGROUPS Recover editable category groups from imported primitives.
function document = inferCompoundGroups(document)
document = groupSourceParents(document);
for panelId = reshape(string({document.panels.id}), 1, [])
    document = pairRoles(document, panelId, ...
        "significance-label", "significance-bracket", "Significance bracket");
    document = pairRoles(document, panelId, ...
        "scale-label", "scale-bar", "Scale bar");
    document = pairRoles(document, panelId, ...
        "measurement-label", "measurement-point", "Measurement");
end
end

function document = groupSourceParents(document)
keys = strings(numel(document.nodes), 1);
for k = 1:numel(document.nodes)
    metadata = document.nodes(k).metadata;
    tag = fieldValue(metadata, "sourceGroupTag", "");
    name = fieldValue(metadata, "sourceGroupName", "");
    keys(k) = string(tag) + "|" + string(name);
    if keys(k) == "|", keys(k) = ""; end
end
for key = reshape(unique(keys(keys ~= ""), 'stable'), 1, [])
    indices = find(keys == key & string({document.nodes.groupId}).' == "");
    if isempty(indices), continue; end
    parts = split(key, "|");
    groupName = parts(end);
    if strlength(groupName) == 0, groupName = parts(1); end
    [document, groupId] = figure_studio.figureDocument.groupNodes( ...
        document, string({document.nodes(indices).id}), groupName);
    document = setGroupRole(document, groupId, "source-group");
end
end

function document = pairRoles(document, panelId, labelRole, graphicRole, name)
labels = find(string({document.nodes.panelId}) == panelId & ...
    string({document.nodes.role}) == labelRole & ...
    string({document.nodes.groupId}) == "");
for labelIndex = reshape(labels, 1, [])
    candidates = find(string({document.nodes.panelId}) == panelId & ...
        string({document.nodes.role}) == graphicRole & ...
        string({document.nodes.groupId}) == "");
    if isempty(candidates), continue; end
    distances = inf(size(candidates));
    labelPosition = nodeCenter(document.nodes(labelIndex));
    for k = 1:numel(candidates)
        distances(k) = norm(nodeCenter(document.nodes(candidates(k))) - ...
            labelPosition);
    end
    [~, nearest] = min(distances);
    ids = string({document.nodes([labelIndex candidates(nearest)]).id});
    [document, groupId] = figure_studio.figureDocument.groupNodes(document, ids, name);
    document = setGroupRole(document, groupId, "compound-annotation");
end
end

function document = setGroupRole(document, groupId, role)
index = find(string({document.nodes.id}) == groupId, 1);
document.nodes(index).role = role;
end

function center = nodeCenter(node)
x = node.data.x;
y = node.data.y;
if isempty(x) && isfield(node.metadata, "position")
    position = node.metadata.position;
    x = position(1) + position(3)/2;
    y = position(2) + position(4)/2;
end
if isempty(x), x = 0; end
if isempty(y), y = 0; end
center = [mean(double(x(:)), 'omitnan'), mean(double(y(:)), 'omitnan')];
center(~isfinite(center)) = 0;
end

function result = fieldValue(owner, name, fallback)
if isfield(owner, name), result = owner.(name); else, result = fallback; end
end
