% Expected caller: Runtime V2. Input is canonical EIS state. Output is a
% deterministic files/summary/overlay model with no UI access or side effects.
function view = presentWorkbench(state)
    items = state.session.cache.items;
    selected = selectedItems(items, state.session.selection.paths);
    view = struct();
    view.controls.files = filePanelSpec( ...
        items, state.session.selection.paths);
    if isempty(items)
        summary = {'No files loaded.'};
    elseif isempty(selected)
        summary = {'No files selected.'};
    else
        summary = eis.userInterface.buildSummary(selected);
    end
    view.controls.summary = struct("Value", {summary});
    view.previews.plot.Axes.overlay = struct( ...
        "Renderer", "overlay", ...
        "Model", axisModel(selected, state.project.parameters));
end

function model = axisModel(items, parameters)
    model = struct( ...
        "items", items, ...
        "options", parameters, ...
        "hasItems", ~isempty(items));
end

function spec = filePanelSpec(items, selectedPaths)
    files = struct("id", {}, "path", {}, "status", {});
    for k = 1:numel(items)
        files(end + 1) = struct( ...
            "id", "item" + string(k), ...
            "path", string(items(k).filepath), "status", "");
    end
    selection = strings(0, 1);
    if ~isempty(items)
        paths = string({items.filepath});
        indices = find(ismember(paths, selectedPaths(:)));
        selection = "item" + string(indices(:));
    end
    status = "No files loaded";
    if ~isempty(items)
        status = string(numel(items)) + " file(s) loaded";
    end
    spec = struct("Files", files, "Selection", selection, "Status", status);
end

function items = selectedItems(items, selectedPaths)
    if isempty(items)
        return;
    end
    keep = ismember(string({items.filepath}), selectedPaths(:));
    items = items(keep);
end
