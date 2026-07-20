function applicationState = changePreset( ...
        applicationState, preset, callbackContext)
%CHANGEPRESET Apply one declared control-bound preset to the current image.
item = applicationState.session.cache.currentItem;
if isempty(item)
    return
end
items = string( ...
    flir_thermal.thermalPreview.presentationData.rangePresetItems());
preset = string(preset);
if ~any(preset == items)
    return
end
bounds = ...
    flir_thermal.thermalPreview.presentationData.rangeControlBounds( ...
        item, preset, item.rangeControlBounds);
item.rangePreset = preset;
item.rangeControlBounds = bounds;
range = clampRange(item.displayRange, bounds);
if ~isequaln(range, item.displayRange)
    item.displayRange = range;
    item.rangeAdjusted = true;
end
applicationState = flir_thermal.thermalSources.storeCurrentAnnotation( ...
    applicationState, item);
applicationState = invalidateResults(applicationState);
callbackContext.appendStatus("Thermal range bounds: " + preset + ".");
end

function range = clampRange(range, bounds)
range = sort(double(range(:).'));
range = min(bounds(2), max(bounds(1), range));
if numel(range) ~= 2 || any(~isfinite(range)) || range(2) <= range(1)
    range = double(bounds(:).');
end
end

function applicationState = invalidateResults(applicationState)
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
end
