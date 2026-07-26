% App-owned implementation for flir_thermal.displayMapping.autoRange within the flir_thermal product workflow.
function applicationState = autoRange( ...
        applicationState, callbackContext)
%AUTORANGE Fit the selected image range to finite thermal values.
item = applicationState.session.cache.currentItem;
if isempty(item)
    return
end
values = ...
    flir_thermal.thermalPreview.presentationData.valueMatrix(item);
values = double(values(isfinite(values)));
if isempty(values)
    return
end
range = normalizeRange([min(values), max(values)]);
item.displayRange = range;
item.rangeControlBounds = [ ...
    min(item.rangeControlBounds(1), range(1)), ...
    max(item.rangeControlBounds(2), range(2))];
item.rangeAdjusted = true;
applicationState = flir_thermal.thermalSources.storeCurrentAnnotation( ...
    applicationState, item);
applicationState = invalidateResults(applicationState);
callbackContext.log("info", "flir_thermal.displaymapping.autorange.status", ...
    "Set the selected FLIR auto range.");
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
