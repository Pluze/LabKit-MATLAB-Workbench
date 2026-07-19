% Expected caller: the LabKit App runtime. Binding values, file rows,
% selection, and framework log text are supplied by the runtime; this
% presenter owns only Chrono-specific availability and plot content.
function view = presentWorkbench(state)
    items = selectedItems(state);
    model = struct( ...
        "items", items, ...
        "options", state.project.parameters);
    view = labkit.app.view.Snapshot() ...
        .enabled("exportCurves", ~isempty(items)) ...
        .renderPlot("overlayPlots", "overlay", model);
end

function items = selectedItems(state)
    items = state.session.cache.items;
    indices = state.session.selection.files.Indices;
    indices = indices(indices <= numel(items));
    items = items(indices);
end
