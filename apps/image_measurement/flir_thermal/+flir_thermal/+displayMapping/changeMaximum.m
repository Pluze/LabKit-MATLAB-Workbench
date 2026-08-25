% App-owned implementation for flir_thermal.displayMapping.changeMaximum within the flir_thermal product workflow.
function applicationState = changeMaximum( ...
        applicationState, maximumC, ~)
%CHANGEMAXIMUM Update the current image's display maximum.
item = applicationState.session.cache.currentItem;
maximumC = double(maximumC);
if isempty(item) || ~isscalar(maximumC) || ~isfinite(maximumC)
    return
end
range = normalizedRange(item.displayRange);
range(2) = maximumC;
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
