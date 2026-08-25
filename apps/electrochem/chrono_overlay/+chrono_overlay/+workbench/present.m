% Expected caller: the LabKit App runtime. Binding values, file rows,
% selection, and framework log text are supplied by the runtime; this
% presenter owns only Chrono-specific availability and plot content.
function view = present(state)
    arguments
        state (1, 1) struct
    end
    items = selectedItems(state);
    model = struct( ...
        "items", items, ...
        "options", state.project.parameters);
    view = labkit.app.view.Snapshot() ...
        .renderPlot("overlayPlots", model, ...
        ViewRevision=viewportRevision(state));
end

function revision = viewportRevision(state)
selection = state.session.selection.files;
revision = string(jsonencode(struct( ...
    "sourceIds", {selectedSourceIds( ...
        state.project.inputs.sources, selection)}, ...
    "xAxis", string(state.project.parameters.xAxis))));
end

function ids = selectedSourceIds(sources, selection)
ids = strings(1, 0);
if isempty(sources) || ~isfield(sources, "id")
    return
end
indices = selection.Indices;
indices = indices(indices >= 1 & indices <= numel(sources));
if ~isempty(indices)
    ids = reshape(string({sources(indices).id}), 1, []);
end
end

function items = selectedItems(state)
    items = state.session.cache.items;
    indices = state.session.selection.files.Indices;
    indices = indices(indices <= numel(items));
    items = items(indices);
end
