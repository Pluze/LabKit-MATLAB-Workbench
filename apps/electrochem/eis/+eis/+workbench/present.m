% App-owned implementation for eis.workbench.present within the eis product workflow.
function view = present(state)
model = struct("items", state.session.cache.items, ...
    "options", state.project.parameters, ...
    "hasItems", ~isempty(state.session.cache.items), ...
    "viewAction", state.session.cache.plotViewAction);
summary = "No files loaded.";
if model.hasItems
    summary = string(numel(model.items)) + " file(s) loaded.";
end
view = labkit.app.view.Snapshot().text("summary", summary).renderPlot( ...
    "plot", model, ViewRevision=viewportRevision(state));
end

function revision = viewportRevision(state)
p = state.project.parameters;
selection = state.session.selection.files;
revision = string(jsonencode(struct( ...
    "sourceIds", {selectedSourceIds( ...
        state.project.inputs.sources, selection)}, ...
    "xName", string(p.xName), "yName", string(p.yName), ...
    "impedanceUnit", string(p.impedanceUnit), ...
    "logX", logical(p.logX), "logY", logical(p.logY), ...
    "explicitRevision", state.session.cache.plotViewRevision)));
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
