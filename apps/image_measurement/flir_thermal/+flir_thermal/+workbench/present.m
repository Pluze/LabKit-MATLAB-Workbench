% App-owned implementation for flir_thermal.workbench.present within the flir_thermal product workflow.
function view = present(applicationState)
%PRESENT Compose FLIR Thermal's complete semantic snapshot.
project = applicationState.project;
session = applicationState.session;
sources = project.inputs.sources;
annotations = project.annotations.items;
item = session.cache.currentItem;
index = session.selection.currentIndex;
hasItem = ~isempty(item);
[range, bounds, preset] = rangeState(item);
sourceId = "";
if index >= 1 && index <= numel(sources)
    sourceId = string(sources(index).id);
end
viewRevision = flir_thermal.thermalPreview.viewportRevision( ...
    sourceId, item, range);

summary = flir_thermal.thermalPreview.presentationData.summaryTableData( ...
    item, range, project.parameters.palette);
details = detailLines(applicationState, item);
view = flir_thermal.thermalSources.present( ...
        sources, annotations, index, item) ...
    .include(flir_thermal.displayMapping.present( ...
        project.parameters, annotations, hasItem, range, bounds, preset)) ...
    .include(flir_thermal.resultFiles.present( ...
        project.parameters, hasItem, ~isempty(sources))) ...
    .include(flir_thermal.temperatureReadings.present(hasItem)) ...
    .include(flir_thermal.thermalPreview.present( ...
        item, project.parameters, range, viewRevision)) ...
    .tableData("summaryTable", summary, Columns=["Metric", "Value"]) ...
    .text("details", join(string(details), newline));
end

function [range, bounds, preset] = rangeState(item)
labels = flir_thermal.thermalPreview.presentationData.rangeControlLabels();
range = [20 40];
bounds = [-20 120];
preset = labels.defaultPreset;
if isempty(item)
    return
end
range = normalizeRange(item.displayRange, [20 40]);
bounds = normalizeRange(item.rangeControlBounds, [-20 120]);
bounds = [min(bounds(1), range(1)), max(bounds(2), range(2))];
preset = string(item.rangePreset);
end

function range = normalizeRange(value, fallback)
range = double(value(:).');
if numel(range) ~= 2 || any(~isfinite(range))
    range = fallback;
end
range = sort(range);
if range(2) <= range(1)
    range(2) = range(1) + 1;
end
end

function lines = detailLines(applicationState, item)
folder = applicationState.project.parameters.outputFolder;
if isempty(item)
    lines = flir_thermal.thermalPreview.presentationData.detailLines( ...
        [], 0, folder);
else
    lines = flir_thermal.thermalPreview.presentationData.detailLines( ...
        item, 1, folder);
    lines{1} = sprintf("Loaded files: %d", ...
        numel(applicationState.project.inputs.sources));
end
manifest = string(applicationState.project.results.resultManifestPath);
if strlength(manifest) > 0
    lines{end + 1} = char("Last result manifest: " + manifest);
end
end
