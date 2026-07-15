% Expected caller: the LabKit V2 runtime. Input is canonical FLIR Thermal
% state. Output is deterministic controls, two preview axes, and one
% transient point/region semantic interaction.
function view = presentWorkbench(state)
    sources = state.project.inputs.sources;
    annotations = state.project.annotations.items;
    index = state.session.selection.currentIndex;
    item = state.session.cache.currentItem;
    hasItem = ~isempty(item);
    p = state.project.parameters;
    [range, bounds, preset] = rangeState(item);

    view = struct();
    view.controls.thermalFiles = fileSpec(sources, annotations, index);
    view.controls.fileStatus = valueSpec(fileStatus(sources, index, item));
    view.controls.currentImage = valueSpec(currentImageText(item));
    view.controls.previousImage = enabledSpec(hasItem && index > 1);
    view.controls.nextImage = enabledSpec(hasItem && index < numel(sources));
    view.controls.palette = valueSpec(p.palette);
    view.controls.colorMapping = valueSpec(p.colorMapping);
    view.controls.gammaValue = valueSpec(p.gammaValue);
    view.controls.rangePreset = controlSpec(hasItem, preset);
    view.controls.temperatureMin = rangeSpec(hasItem, range(1), bounds);
    view.controls.temperatureMax = rangeSpec(hasItem, range(2), bounds);
    view.controls.autoRange = enabledSpec(hasItem);
    view.controls.groupRange = enabledSpec(hasItem);
    view.controls.perImageRange = enabledSpec(hasItem);
    view.controls.roundRange = enabledSpec(anyAdjusted(annotations));
    view.controls.roiHotMode = enabledSpec(hasItem);
    view.controls.roiColdMode = enabledSpec(hasItem);
    view.controls.roiMeanMode = enabledSpec(hasItem);
    view.controls.summaryTable = dataSpec( ...
        flir_thermal.userInterface.summaryTableData(item, range, p.palette));
    view.controls.outputFolder = valueSpec(p.outputFolder);
    view.controls.exportFormat = valueSpec(p.exportFormat);
    view.controls.exportCurrent = enabledSpec(hasItem);
    view.controls.exportAll = enabledSpec(~isempty(sources));
    view.controls.details = valueSpec(detailLines(state, item));
    view.controls.logPanel = valueSpec(cellstr(state.session.workflow.logLines));

    model = previewModel(item, p, range);
    view.previews.preview.Axes.thermalImage = struct( ...
        "Renderer", "thermalPreview", "Model", model);
    view.previews.preview.Axes.temperatureScale = struct( ...
        "Renderer", "temperatureScale", "Model", model);
    if hasItem
        [values] = flir_thermal.userInterface.valueMatrix(item);
        view.interactions.temperatureReading = struct( ...
            "Kind", "regionSelection", ...
            "Targets", "preview.thermalImage", ...
            "Value", [], ...
            "Event", "temperatureRegionSelected", ...
            "BackgroundEvent", "temperaturePointSelected", ...
            "ImageSize", size(values), ...
            "ChangePolicy", "commit", ...
            "Options", struct("color", [1 1 1], ...
            "lineWidth", 1.2, "pointThreshold", 2));
    end
end

function spec = fileSpec(sources, annotations, index)
    files = repmat(struct("id", "", "path", "", "status", "ready"), ...
        numel(sources), 1);
    for k = 1:numel(sources)
        files(k).id = string(sources(k).id);
        files(k).path = string(sources(k).reference.originalPath);
        annotation = annotationFor(annotations, sources(k).id);
        if ~isempty(annotation) && logical(annotation.rangeAdjusted)
            files(k).status = "range set";
        else
            files(k).status = "needs range";
        end
    end
    selection = strings(0, 1);
    if index >= 1 && index <= numel(sources)
        selection = string(sources(index).id);
    end
    spec = struct();
    spec.Files = files;
    spec.Selection = selection;
end

function value = fileStatus(sources, index, item)
    if isempty(item)
        value = "Files: " + string(numel(sources));
        return;
    end
    if logical(item.rangeAdjusted)
        status = "range set";
    else
        status = "needs range";
    end
    value = sprintf('Files: %d | Current: %d/%d | %s', ...
        numel(sources), index, numel(sources), status);
end

function value = currentImageText(item)
    if isempty(item)
        value = "No FLIR image loaded";
    elseif logical(item.rangeAdjusted)
        value = string(item.name) + " (range set)";
    else
        value = string(item.name) + " (needs range)";
    end
end

function [range, bounds, preset] = rangeState(item)
    labels = flir_thermal.userInterface.rangeControlLabels();
    range = [20 40];
    bounds = [-20 120];
    preset = labels.defaultPreset;
    if isempty(item)
        return;
    end
    range = normalizeRange(item.displayRange);
    bounds = normalizeRange(item.rangeControlBounds);
    bounds = [min(bounds(1), range(1)), max(bounds(2), range(2))];
    preset = string(item.rangePreset);
end

function model = previewModel(item, parameters, range)
    values = [];
    units = "C";
    titleText = "Clean thermal image";
    if ~isempty(item)
        [values, units, titleText] = ...
            flir_thermal.userInterface.valueMatrix(item);
    end
    model = struct( ...
        "values", values, ...
        "item", item, ...
        "range", range, ...
        "units", units, ...
        "title", titleText, ...
        "palette", parameters.palette, ...
        "colorMapping", parameters.colorMapping, ...
        "gammaValue", parameters.gammaValue);
end

function lines = detailLines(state, item)
    folder = state.project.parameters.outputFolder;
    if isempty(item)
        lines = flir_thermal.userInterface.detailLines([], 0, folder);
    else
        lines = flir_thermal.userInterface.detailLines(item, 1, folder);
        lines{1} = sprintf('Loaded files: %d', ...
            numel(state.project.inputs.sources));
    end
    if strlength(state.project.results.resultManifestPath) > 0
        lines{end + 1} = char("Last result manifest: " + ...
            state.project.results.resultManifestPath);
    end
end

function annotation = annotationFor(annotations, sourceId)
    annotation = [];
    index = find(string({annotations.sourceId}) == string(sourceId), 1);
    if ~isempty(index)
        annotation = annotations(index);
    end
end

function tf = anyAdjusted(annotations)
    tf = false;
    if ~isempty(annotations)
        tf = any(logical([annotations.rangeAdjusted]));
    end
end

function range = normalizeRange(value)
    range = double(value(:).');
    if numel(range) ~= 2 || ~all(isfinite(range))
        range = [20 40];
    end
    range = sort(range);
    if range(2) <= range(1)
        range(2) = range(1) + 1;
    end
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = dataSpec(value)
    spec = struct();
    spec.Data = value;
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end

function spec = controlSpec(enabled, value)
    spec = struct("Enabled", logical(enabled), "Value", value);
end

function spec = rangeSpec(enabled, value, limits)
    spec = struct("Enabled", logical(enabled), "Value", value, ...
        "Limits", limits);
end
