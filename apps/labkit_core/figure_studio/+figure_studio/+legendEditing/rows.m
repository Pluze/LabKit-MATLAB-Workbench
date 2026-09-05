function rows = rows(document, panelId)
%ROWS Resolve editable legend series in the active panel, in legend order.
% Node names and legendVisible are authoritative. Optional node metadata owns
% legend position independently of graphics stacking and survives duplication.
rows = struct("nodeId", {}, "sourceLabel", {}, "label", {}, "enabled", {});
if isempty(document.panels), return; end
index = find(string({document.panels.id}) == string(panelId), 1);
if isempty(index), index = 1; end
panel = document.panels(index);
nodes = document.nodes(string({document.nodes.panelId}) == panel.id & ...
    ismember(string({document.nodes.kind}), ["line", "bar", "errorbar", ...
    "area", "scatter", "surface", "patch", "constantline", "boxchart"]));
positions = (1:numel(nodes)).';
for k = 1:numel(nodes)
    sourceLabel = nodes(k).name;
    if isfield(nodes(k).metadata, "sourceLegendName")
        sourceLabel = nodes(k).metadata.sourceLegendName;
    end
    rows(k, 1) = struct("nodeId", nodes(k).id, "sourceLabel", sourceLabel, ...
        "label", nodes(k).name, ...
        "enabled", nodes(k).legendVisible);
    if isfield(nodes(k).metadata, "legendPosition")
        positions(k) = nodes(k).metadata.legendPosition;
    elseif isfield(panel.legend, "strings")
        sourceIndex = find(string(panel.legend.strings) == nodes(k).name, 1);
        if ~isempty(sourceIndex)
            positions(k) = sourceIndex;
        else
            positions(k) = numel(nodes) + k;
            if isfield(panel.legend, "enabled") && panel.legend.enabled
                rows(k).enabled = false;
            end
        end
    end
end
[~, order] = sort(positions);
rows = rows(order);
end
