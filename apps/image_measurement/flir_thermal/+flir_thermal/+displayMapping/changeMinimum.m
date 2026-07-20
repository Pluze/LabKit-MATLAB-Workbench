function applicationState = changeMinimum( ...
        applicationState, minimumC, callbackContext)
%CHANGEMINIMUM Update the current image's display minimum.
item = applicationState.session.cache.currentItem;
minimumC = double(minimumC);
if isempty(item) || ~isscalar(minimumC) || ~isfinite(minimumC)
    return
end
range = normalizedRange(item.displayRange);
range(1) = minimumC;
range = normalizedRange(range);
item.displayRange = range;
item.rangeControlBounds = [ ...
    min(item.rangeControlBounds(1), range(1)), ...
    max(item.rangeControlBounds(2), range(2))];
item.rangeAdjusted = true;
applicationState = flir_thermal.thermalSources.storeCurrentAnnotation( ...
    applicationState, item);
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
callbackContext.appendStatus("Updated current thermal display range.");
end

function range = normalizedRange(value)
range = double(value(:).');
if numel(range) ~= 2 || any(~isfinite(range))
    range = [20 40];
end
range = sort(range);
if range(2) <= range(1)
    range(2) = range(1) + 1;
end
end
