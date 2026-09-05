function document = replaceRows(document, panelId, rows)
%REPLACEROWS Store complete legend presentation against stable object identities.
% Called by the legend editor. This changes names and legend membership only.
index = find(string({document.panels.id}) == string(panelId), 1);
if isempty(index), error("figure_studio:legendEditing:UnknownPanel", "Select a panel first."); end
for k = 1:numel(rows)
    nodeIndex = find(string({document.nodes.id}) == rows(k).nodeId & ...
        string({document.nodes.panelId}) == panelId, 1);
    if isempty(nodeIndex)
        error("figure_studio:legendEditing:UnknownObject", "The legend object is no longer available.");
    end
    if ~isfield(document.nodes(nodeIndex).metadata, "sourceLegendName")
        document.nodes(nodeIndex).metadata.sourceLegendName = document.nodes(nodeIndex).name;
    end
    document.nodes(nodeIndex).name = rows(k).label;
    document.nodes(nodeIndex).legendVisible = rows(k).enabled;
    document.nodes(nodeIndex).metadata.legendPosition = k;
end
document.panels(index).legend.edited = true;
document.panels(index).legend.enabled = any([rows.enabled]);
document.panels(index).legend.strings = string({rows([rows.enabled]).label});
end
