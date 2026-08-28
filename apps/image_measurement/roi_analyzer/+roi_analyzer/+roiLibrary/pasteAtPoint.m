function applicationState = pasteAtPoint(applicationState, previewPoint, callbackContext)
%PASTEATPOINT Place copied ROIs around one clicked image point.
clipboard = applicationState.session.clipboard;
if ~clipboard.pastePending || isempty(clipboard.rois)
    return
end
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
scale = applicationState.session.cache.previewScale;
point = double(previewPoint(:).');
if strlength(annotation.sourceId) == 0 || numel(point) ~= 2 || ...
        any(~isfinite(point)) || ~isfinite(scale) || scale <= 0
    return
end
target = (point - 0.5) ./ scale + 0.5;
rois = clipboard.rois;
centers = vertcat(rois.centerXY) - clipboard.anchor + target;
[centers, fits] = roi_analyzer.roiLibrary.fitCentersToImage(centers, rois, ...
    applicationState.project.annotations.templates, ...
    size(applicationState.session.cache.image));
if ~fits
    callbackContext.alert( ...
        "The copied ROI group is larger than this image and cannot be placed without changing its relative layout.", ...
        "ROI group does not fit");
    return
end
existingIds = string({annotation.rois.id});
existingNames = string({annotation.rois.name});
firstNew = numel(annotation.rois) + 1;
existingCount = numel(existingIds);
existingIds = [existingIds, strings(1, numel(rois))];
existingNames = [existingNames, strings(1, numel(rois))];
for index = 1:numel(rois)
    assigned = 1:(existingCount + index - 1);
    rois(index).id = roi_analyzer.roiLibrary.nextId( ...
        existingIds(assigned), "roi-");
    existingIds(existingCount + index) = rois(index).id;
    rois(index).name = uniqueName( ...
        rois(index).name, existingNames(assigned));
    existingNames(existingCount + index) = rois(index).name;
    rois(index).centerXY = centers(index, :);
    annotation.rois(end + 1, 1) = rois(index);
end
applicationState = roi_analyzer.roiLibrary.storeAnnotation( ...
    applicationState, annotation);
newIndices = firstNew:numel(annotation.rois);
applicationState.session.selection.roiIndex = newIndices(1);
applicationState.session.selection.roiIndices = newIndices;
applicationState.session.clipboard.pastePending = false;
end

function name = uniqueName(original, existing)
original = string(original);
name = original;
if ~any(existing == name)
    return
end
name = original + " copy";
suffix = 2;
while any(existing == name)
    name = original + " copy " + suffix;
    suffix = suffix + 1;
end
end
