function applicationState = roundRanges( ...
        applicationState, callbackContext)
%ROUNDRANGES Round every explicitly set range outward to whole Celsius.
annotations = applicationState.project.annotations.items;
count = 0;
for k = 1:numel(annotations)
    if ~logical(annotations(k).rangeAdjusted)
        continue
    end
    range = sort(double(annotations(k).displayRange(:).'));
    range = [floor(range(1)), ceil(range(2))];
    if range(2) <= range(1)
        range(2) = range(1) + 1;
    end
    annotations(k).displayRange = range;
    annotations(k).rangeControlBounds = [ ...
        min(annotations(k).rangeControlBounds(1), range(1)), ...
        max(annotations(k).rangeControlBounds(2), range(2))];
    count = count + 1;
end
applicationState.project.annotations.items = annotations;
index = applicationState.session.selection.currentIndex;
if index >= 1 && index <= ...
        numel(applicationState.project.inputs.sources)
    sourceId = applicationState.project.inputs.sources(index).id;
    match = find(string({annotations.sourceId}) == string(sourceId), 1);
    if ~isempty(match) && ...
            ~isempty(applicationState.session.cache.currentItem)
        applicationState.session.cache.currentItem = ...
            flir_thermal.thermalAnnotations.apply( ...
                applicationState.session.cache.currentItem, ...
                annotations(match));
    end
end
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
callbackContext.appendStatus( ...
    "Rounded " + string(count) + " thermal ranges.");
end
