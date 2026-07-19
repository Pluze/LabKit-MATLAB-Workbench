function view = present(state)
model = struct("items", state.session.cache.items, "options", state.project.parameters, "hasItems", ~isempty(state.session.cache.items));
summary = "No files loaded.";
if model.hasItems
    summary = string(numel(model.items)) + " file(s) loaded.";
end
view = labkit.app.view.Snapshot().text("summary", summary).renderPlot("plot", model);
end
