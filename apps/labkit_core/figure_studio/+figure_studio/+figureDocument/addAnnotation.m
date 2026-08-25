%ADDANNOTATION Add one editable scientific annotation or compound group.
function [document, ids] = addAnnotation(document, panelId, specification)
arguments
    document (1, 1) struct
    panelId (1, 1) string
    specification (1, 1) struct
end
kind = lower(string(value(specification, "kind", "text")));
textValue = string(value(specification, "text", "Annotation"));
x1 = finiteValue(specification, "x1", 0);
y1 = finiteValue(specification, "y1", 0);
x2 = finiteValue(specification, "x2", x1 + 1);
y2 = finiteValue(specification, "y2", y1 + 1);
switch kind
    case "text"
        [document, ids] = appendNode(document, annotationNode( ...
            panelId, "text", "annotation-text", textValue, ...
            struct("x", [x1 y1 0]), struct("text", textValue), struct()));
    case "arrow"
        style = struct("LineStyle", "-", "Marker", ">", ...
            "MarkerIndices", 2, "LineWidth", 1.5);
        [document, ids] = appendNode(document, annotationNode( ...
            panelId, "line", "annotation-arrow", textValue, ...
            struct("x", [x1 x2], "y", [y1 y2]), struct(), style));
    case "reference line"
        metadata = struct("value", y1, "interceptAxis", "y", ...
            "label", textValue);
        [document, ids] = appendNode(document, annotationNode( ...
            panelId, "constantline", "reference-line", textValue, ...
            struct(), metadata, struct("LineStyle", "--")));
    case "region"
        position = [min(x1, x2), min(y1, y2), abs(x2-x1), abs(y2-y1)];
        style = struct("FaceColor", [0.8 0.8 0.8], ...
            "FaceAlpha", 0.2, "EdgeColor", [0.4 0.4 0.4]);
        [document, ids] = appendNode(document, annotationNode( ...
            panelId, "rectangle", "analysis-window", textValue, ...
            struct(), struct("position", position, "curvature", [0 0]), style));
    case "scale bar"
        [document, groupId] = appendGroup(document, panelId, "Scale bar");
        [document, lineId] = appendNode(document, withGroup(annotationNode( ...
            panelId, "line", "scale-bar", "Scale bar", ...
            struct("x", [x1 x2], "y", [y1 y1]), struct(), ...
            struct("LineWidth", 2)), groupId));
        [document, textId] = appendNode(document, withGroup(annotationNode( ...
            panelId, "text", "scale-label", textValue, ...
            struct("x", [mean([x1 x2]) y1 0]), struct("text", textValue), ...
            struct("HorizontalAlignment", "center", ...
                "VerticalAlignment", "top")), groupId));
        ids = [groupId; lineId; textId];
    case "significance bracket"
        [document, groupId] = appendGroup(document, panelId, ...
            "Significance bracket");
        bracketY = max(y1, y2);
        [document, lineId] = appendNode(document, withGroup(annotationNode( ...
            panelId, "line", "significance-bracket", "Bracket", ...
            struct("x", [x1 x1 x2 x2], ...
                "y", [y1 bracketY bracketY y2]), struct(), ...
            struct("LineWidth", 1.25)), groupId));
        [document, textId] = appendNode(document, withGroup(annotationNode( ...
            panelId, "text", "significance-label", textValue, ...
            struct("x", [mean([x1 x2]) bracketY 0]), ...
            struct("text", textValue), ...
            struct("HorizontalAlignment", "center", ...
                "VerticalAlignment", "bottom")), groupId));
        ids = [groupId; lineId; textId];
    case "measurement"
        [document, groupId] = appendGroup(document, panelId, "Measurement");
        [document, pointId] = appendNode(document, withGroup(annotationNode( ...
            panelId, "scatter", "measurement-point", "Measurement point", ...
            struct("x", x1, "y", y1), struct(), ...
            struct("Marker", "o", "MarkerFaceColor", "auto")), groupId));
        [document, textId] = appendNode(document, withGroup(annotationNode( ...
            panelId, "text", "measurement-label", textValue, ...
            struct("x", [x1 y1 0]), struct("text", textValue), ...
            struct("VerticalAlignment", "bottom")), groupId));
        ids = [groupId; pointId; textId];
    otherwise
        error("figure_studio:figureDocument:UnknownAnnotation", ...
            "Unknown annotation type: %s", kind);
end
document = includeCoordinates(document, panelId, [x1 x2], [y1 y2]);
document.selection = ids(end);
end

function document = includeCoordinates(document, panelId, x, y)
panelIndex = find(string({document.panels.id}) == panelId, 1);
if isempty(panelIndex), return; end
for axisName = ["x", "y"]
    if axisName == "x", coordinates = x; else, coordinates = y; end
    coordinates = coordinates(isfinite(coordinates));
    if isempty(coordinates), continue; end
    axisValue = document.panels(panelIndex).axes.(char(axisName));
    limits = axisValue.limits;
    span = max(diff(limits), max(abs(limits)) * eps + 1);
    expanded = [min(limits(1), min(coordinates) - 0.04 * span), ...
        max(limits(2), max(coordinates) + 0.08 * span)];
    if ~isequal(expanded, limits)
        axisValue.limits = expanded;
        if lower(string(axisValue.locator.mode)) == "source"
            axisValue.locator.mode = "auto";
            axisValue.formatter.mode = "auto";
        end
        axisValue.ticks = figure_studio.figureDocument.planTicks(axisValue);
        document.panels(panelIndex).axes.(char(axisName)) = axisValue;
    end
end
end

function node = annotationNode(panelId, kind, role, name, data, metadata, style)
node = nodeTemplate();
node.panelId = panelId;
node.kind = kind;
node.role = role;
node.name = name;
node.dataLocked = false;
for field = string(fieldnames(data)).'
    node.data.(char(field)) = data.(char(field));
end
node.metadata = metadata;
node.sourceStyle = style;
end

function node = withGroup(node, groupId)
node.groupId = groupId;
node.parentId = groupId;
end

function [document, id] = appendGroup(document, panelId, name)
node = nodeTemplate();
node.panelId = panelId;
node.kind = "group";
node.role = "compound-annotation";
node.name = name;
node.dataLocked = false;
[document, id] = appendNode(document, node);
end

function [document, id] = appendNode(document, node)
id = nextId(document);
node.id = id;
document.nodes(end + 1, 1) = node;
end

function id = nextId(document)
numbers = zeros(numel(document.nodes), 1);
for k = 1:numel(document.nodes)
    token = regexp(char(document.nodes(k).id), '(\d+)$', 'tokens', 'once');
    if ~isempty(token), numbers(k) = str2double(token{1}); end
end
id = "object-" + string(max([numbers; 0]) + 1);
end

function node = nodeTemplate()
node = struct("id", "", "panelId", "", "parentId", "", ...
    "groupId", "", "kind", "", "role", "", "name", "", ...
    "visible", true, "locked", false, "dataLocked", true, ...
    "legendVisible", false, "data", struct("x", [], "y", [], ...
        "z", [], "c", [], "alpha", []), ...
    "sourceStyle", struct(), "overrides", struct(), "metadata", struct());
end

function result = finiteValue(owner, name, fallback)
result = double(value(owner, name, fallback));
if ~isscalar(result) || ~isfinite(result), result = fallback; end
end

function result = value(owner, name, fallback)
if isfield(owner, name), result = owner.(name); else, result = fallback; end
end
