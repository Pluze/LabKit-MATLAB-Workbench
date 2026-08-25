%EDITORSTATE Create transient selection and undo state for one document.
function editor = editorState(plotData)
document = figure_studio.figureDocument.create(plotData);
historyValue = figure_studio.figureDocument.history("create", [], document);
editor = struct("document", document, "history", historyValue, ...
    "activePanelId", firstPanelId(document), ...
    "axisTarget", "X", "selectedTickRows", zeros(0, 1), ...
    "nativePassThrough", true, ...
    "activeScope", "Selection", "activeProperty", "LineWidth", ...
    "propertyDraft", "", "layerNodeIds", strings(0, 1));
end

function id = firstPanelId(document)
if isempty(document.panels)
    id = "";
else
    id = document.panels(1).id;
end
end
