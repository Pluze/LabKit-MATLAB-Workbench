function copySelectedPlots(obj)
% Offer explicit cross-page selection without changing active workspace tabs.
handles = gobjects(obj.Axes.Count, 1);
labels = strings(obj.Axes.Count, 1);
count = 0;
nodes = obj.Plan.Nodes;
for k = 1:numel(nodes)
    node = nodes(k);
    if node.Kind ~= "plotArea", continue; end
    owner = obj.owningNode(node.Id);
    pageTitle = "Workspace";
    inWorkspace = isempty(obj.WorkbenchWorkspace);
    while ~isempty(owner)
        if owner.Kind == "workspacePage"
            pageTitle = owner.Configuration.Title;
        elseif owner.Kind == "workspace"
            inWorkspace = true;
        end
        owner = obj.owningNode(owner.Id);
    end
    if ~inWorkspace, continue; end
    for axisIndex = 1:numel(node.AxisIds)
        key = labkit.app.internal.native.NativeAdapterValues.axisKey( ...
            node.Id, node.AxisIds(axisIndex));
        count = count + 1;
        handles(count) = obj.Axes(char(key));
        title = labkit.app.internal.native.NativeAdapterValues.axisText( ...
            node.Configuration.AxisTitles, node.AxisIds, axisIndex);
        labels(count) = pageTitle + " — " + title;
    end
end
handles = handles(1:count);
labels = labels(1:count);
if isempty(handles), return; end
current = obj.currentPlotAxes();
initial = find(ismember(handles, current));
if isempty(initial), initial = 1; end
[indices, accepted] = listdlg(ListString=cellstr(labels), ...
    InitialValue=initial, SelectionMode="multiple", ...
    Name="Copy Selected Plots", ...
    PromptString="Select plots to copy together in a grid.", ListSize=[420 300]);
if ~accepted || isempty(indices), return; end
obj.Runtime.performPlotOperation("plots.copy_selected", ...
    @() copySelection(handles(indices)));
end

function copySelection(handles)
canvas = labkit.app.internal.native.createPlotImageFigure(handles, Layout="grid");
cleanup = onCleanup(@() delete(canvas));
copygraphics(canvas, ContentType="image", Resolution=150);
end
