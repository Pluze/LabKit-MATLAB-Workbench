function applicationState = perImageRange( ...
        applicationState, callbackContext)
%PERIMAGERANGE Apply an independent finite range to every registered image.
sources = applicationState.project.inputs.sources;
if isempty(sources)
    return
end
try
    paths = callbackContext.resolveSourcePaths(sources);
    items = flir_thermal.sourceFiles.readImages( ...
        paths, struct("SkipInvalid", false));
catch ME
    callbackContext.reportError("Load FLIR sources for individual ranges", ME);
    callbackContext.alert(ME.message, "Could not load FLIR sources");
    return
end
annotations = applicationState.project.annotations.items;
for k = 1:numel(items)
    old = find(string({annotations.sourceId}) == ...
        string(sources(k).id), 1);
    if ~isempty(old)
        items(k) = flir_thermal.thermalAnnotations.apply( ...
            items(k), annotations(old));
    end
    values = flir_thermal.thermalPreview.presentationData.valueMatrix( ...
        items(k));
    values = double(values(isfinite(values)));
    if isempty(values)
        range = normalizeRange(items(k).displayRange);
    else
        range = normalizeRange([min(values), max(values)]);
    end
    items(k).displayRange = range;
    items(k).rangeControlBounds = range;
    items(k).rangeAdjusted = true;
    annotation = flir_thermal.thermalAnnotations.fromItem( ...
        items(k), sources(k).id);
    if isempty(old)
        annotations(end + 1, 1) = annotation;
    else
        annotations(old) = annotation;
    end
end
applicationState.project.annotations.items = annotations;
index = applicationState.session.selection.currentIndex;
if index >= 1 && index <= numel(items)
    applicationState.session.cache.currentItem = items(index);
end
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
callbackContext.appendStatus( ...
    "Applied individual auto ranges to " + ...
    string(numel(items)) + " thermal images.");
end

function range = normalizeRange(range)
range = sort(double(range(:).'));
if range(2) <= range(1)
    range = range + [-0.5 0.5];
end
end
