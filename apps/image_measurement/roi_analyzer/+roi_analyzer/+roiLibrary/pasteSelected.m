function applicationState = pasteSelected(applicationState, callbackContext)
%PASTESELECTED Paste copied ROIs using predictable image-aware placement.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
clipboard = applicationState.session.clipboard;
if isempty(clipboard.rois) || ...
        strlength(annotation.sourceId) == 0
    return
end
rois = clipboard.rois;
sourceCenters = vertcat(rois.centerXY);
templates = applicationState.project.annotations.templates;
imageSize = size(applicationState.session.cache.image);
if annotation.sourceId == string(clipboard.sourceId)
    sameImageOffsetPixels = [10 10];
    desiredCenters = sourceCenters + sameImageOffsetPixels;
    [centers, fits] = roi_analyzer.roiLibrary.fitCentersToImage( ...
        desiredCenters, rois, templates, imageSize);
else
    [adjusted, fits] = roi_analyzer.roiLibrary.fitCentersToImage( ...
        sourceCenters, rois, templates, imageSize);
    keepsSourceCoordinates = fits && isequal(adjusted, sourceCenters);
    if keepsSourceCoordinates
        centers = sourceCenters;
    else
        targetCenter = [(imageSize(2) + 1) / 2, (imageSize(1) + 1) / 2];
        desiredCenters = sourceCenters - clipboard.anchor + targetCenter;
        [centers, fits] = roi_analyzer.roiLibrary.fitCentersToImage( ...
            desiredCenters, rois, templates, imageSize);
    end
end
if ~fits
    callbackContext.alert( ...
        "The copied ROI group is larger than this image and cannot be pasted without changing its geometry or relative layout.", ...
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
