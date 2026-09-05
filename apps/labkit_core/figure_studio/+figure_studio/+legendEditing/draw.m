function draw(document, panelId, ax)
%DRAW Rebuild an edited legend before base styling, using explicit series handles.
% Called by preview and export rendering. Never changes the source axes or data.
setappdata(ax, 'figureStudioEmptyLegend', false);
if isempty(document) || isempty(document.panels), return; end
index = find(string({document.panels.id}) == string(panelId), 1);
if isempty(index), index = 1; end
panel = document.panels(index);
if ~isfield(panel.legend, "edited") || ~panel.legend.edited, return; end
rows = figure_studio.legendEditing.rows(document, panel.id);
[nodes, handles] = figure_studio.figureDocument.nodeGraphics(document, panel.id, ax);
selected = gobjects(numel(rows), 1);
labels = strings(numel(rows), 1);
count = 0;
for k = 1:numel(rows)
    nodeIndex = find(string({nodes.id}) == rows(k).nodeId, 1);
    if isempty(nodeIndex) || ~isgraphics(handles(nodeIndex)), continue; end
    handle = handles(nodeIndex);
    handle.DisplayName = rows(k).label;
    setappdata(handle, 'figureStudioLegendPosition', k);
    setappdata(handle, 'figureStudioLegendSourceName', rows(k).sourceLabel);
    if rows(k).enabled
        handle.HandleVisibility = 'on';
        count = count + 1;
        selected(count) = handle;
        labels(count) = rows(k).label;
    else
        handle.HandleVisibility = 'off';
    end
end
selected = selected(1:count);
labels = labels(1:count);
if isempty(selected)
    legend(ax, 'off');
    setappdata(ax, 'figureStudioEmptyLegend', true);
    return;
end
lgd = legend(ax, selected, labels, Interpreter="none", AutoUpdate="off");
if isprop(lgd, 'Direction'), lgd.Direction = 'normal'; end
mapping = {"location", "Location"; "orientation", "Orientation"; ...
    "numColumns", "NumColumns"; "box", "Box"};
for k = 1:size(mapping, 1)
    if isfield(panel.legend, mapping{k, 1})
        lgd.(mapping{k, 2}) = panel.legend.(mapping{k, 1});
    end
end
end
