% App-owned implementation for flir_thermal.displayMapping.groupRange within the flir_thermal product workflow.
function applicationState = groupRange( ...
        applicationState, callbackContext)
%GROUPRANGE Apply one finite range spanning every registered FLIR image.
[items, ok] = loadAll(applicationState, callbackContext);
if ~ok
    return
end
ranges = zeros(numel(items), 2);
for k = 1:numel(items)
    ranges(k, :) = automaticRange(items(k));
end
shared = normalizeRange([min(ranges(:, 1)), max(ranges(:, 2))]);
for k = 1:numel(items)
    items(k).displayRange = shared;
    items(k).rangeControlBounds = shared;
    items(k).rangeAdjusted = true;
end
applicationState = storeAll(applicationState, items);
applicationState = invalidateResults(applicationState);
callbackContext.log("info", ...
    "flir_thermal.displaymapping.grouprange.completed", ...
    "Applied one shared range to " + string(numel(items)) + ...
    " thermal images.");
end

function [items, ok] = loadAll(applicationState, callbackContext)
items = repmat(flir_thermal.sourceFiles.emptyItem(), 0, 1);
ok = false;
try
    paths = callbackContext.resolveSourcePaths( ...
        applicationState.project.inputs.sources);
    items = flir_thermal.sourceFiles.readImages( ...
        paths, struct("SkipInvalid", false));
    items = applyAnnotations(items, ...
        applicationState.project.inputs.sources, ...
        applicationState.project.annotations.items);
    ok = numel(items) == numel(applicationState.project.inputs.sources);
catch ME
    callbackContext.reportError("Load FLIR sources for shared range", ME);
    callbackContext.alert(ME.message, "Could not load FLIR sources");
end
end

function items = applyAnnotations(items, sources, annotations)
for k = 1:numel(items)
    match = find(string({annotations.sourceId}) == ...
        string(sources(k).id), 1);
    if ~isempty(match)
        items(k) = flir_thermal.thermalAnnotations.apply( ...
            items(k), annotations(match));
    end
end
end

function applicationState = storeAll(applicationState, items)
sources = applicationState.project.inputs.sources;
annotations = applicationState.project.annotations.items;
for k = 1:numel(items)
    annotation = flir_thermal.thermalAnnotations.fromItem( ...
        items(k), sources(k).id);
    match = find(string({annotations.sourceId}) == ...
        string(sources(k).id), 1);
    if isempty(match)
        annotations(end + 1, 1) = annotation;
    else
        annotations(match) = annotation;
    end
end
applicationState.project.annotations.items = annotations;
index = applicationState.session.selection.currentIndex;
if index >= 1 && index <= numel(items)
    applicationState.session.cache.currentItem = items(index);
end
end

function range = automaticRange(item)
values = ...
    flir_thermal.thermalPreview.presentationData.valueMatrix(item);
values = double(values(isfinite(values)));
if isempty(values)
    range = normalizeRange(item.displayRange);
else
    range = normalizeRange([min(values), max(values)]);
end
end

function range = normalizeRange(range)
range = sort(double(range(:).'));
if range(2) <= range(1)
    range = range + [-0.5 0.5];
end
end

function applicationState = invalidateResults(applicationState)
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
end
