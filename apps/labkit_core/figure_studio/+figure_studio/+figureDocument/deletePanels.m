%DELETEPANELS Delete panels and owned nodes while retaining one panel.
function document = deletePanels(document, panelIds)
panelIds = string(panelIds(:));
existing = string({document.panels.id}).';
remove = ismember(existing, panelIds);
if sum(~remove) < 1
    error("figure_studio:figureDocument:CannotDeleteAllPanels", ...
        "A figure document must retain at least one panel.");
end
removedIds = existing(remove);
document.panels = document.panels(~remove);
document.nodes = document.nodes(~ismember( ...
    string({document.nodes.panelId}), removedIds));
document.selection = document.selection(ismember(document.selection, ...
    string({document.nodes.id})));
end
