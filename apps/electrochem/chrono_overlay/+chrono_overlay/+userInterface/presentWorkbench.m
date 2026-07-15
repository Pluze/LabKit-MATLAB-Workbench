% Expected caller: the LabKit V2 runtime. Input is canonical Chrono Overlay
% state. Output is a deterministic control and multi-axis preview model with
% no access to the UI registry.
function view = presentWorkbench(state)
    items = state.project.inputs.items;
    files = fileEntries(items);
    selectedIds = selectedFileIds(items, state.session.selection.paths);
    plotItems = selectedItems(items, state.session.selection.paths);
    model = struct();
    model.items = plotItems;
    model.options = state.project.parameters;

    view = struct();
    view.controls.files = struct();
    view.controls.files.Files = files;
    view.controls.files.Selection = selectedIds;
    view.controls.files.Status = fileStatus(numel(items));
    view.previews.overlayPlots.Axes.voltage = struct( ...
        "Renderer", "overlay", ...
        "Model", withSignal(model, "voltage"));
    view.previews.overlayPlots.Axes.current = struct( ...
        "Renderer", "overlay", ...
        "Model", withSignal(model, "current"));
end

function value = fileStatus(count)
    if count == 0
        value = "No files loaded";
    else
        value = count + " file(s) loaded";
    end
end

function files = fileEntries(items)
    files = struct("id", {}, "path", {}, "status", {});
    for k = 1:numel(items)
        files(end + 1) = struct( ...
            "id", "item" + string(k), ...
            "path", string(items(k).filepath), ...
            "status", "");
    end
end

function ids = selectedFileIds(items, paths)
    ids = strings(0, 1);
    if isempty(items)
        return;
    end
    mask = ismember(string({items.filepath}), paths(:));
    ids = "item" + string(find(mask)).';
end

function selected = selectedItems(items, paths)
    selected = items;
    if isempty(items)
        return;
    end
    selected = items(ismember(string({items.filepath}), paths(:)));
end

function value = withSignal(model, signal)
    value = model;
    value.signal = string(signal);
end
