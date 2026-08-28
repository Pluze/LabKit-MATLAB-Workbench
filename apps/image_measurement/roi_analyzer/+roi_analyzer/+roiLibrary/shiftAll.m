function applicationState = shiftAll(applicationState, ~)
%SHIFTALL Offset every saved image layout by the entered pixel delta.
delta = [applicationState.session.view.shiftX, ...
    applicationState.session.view.shiftY];
if any(~isfinite(delta))
    return
end
items = applicationState.project.annotations.items;
for itemIndex = 1:numel(items)
    for roiIndex = 1:numel(items(itemIndex).rois)
        items(itemIndex).rois(roiIndex).centerXY = ...
            items(itemIndex).rois(roiIndex).centerXY + delta;
    end
end
applicationState.project.annotations.items = items;
applicationState = roi_analyzer.analysisRun.invalidateAll(applicationState);
end
