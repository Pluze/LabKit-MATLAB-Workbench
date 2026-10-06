function view = present(sources, annotations, index, item)
%PRESENT Describe source rows, navigation, and current image status.
sourceCount = numel(sources);
hasItem = ~isempty(item);
statuses = strings(1, sourceCount);
for k = 1:sourceCount
    annotation = annotationFor(annotations, sources(k).id);
    if ~isempty(annotation) && logical(annotation.rangeAdjusted)
        statuses(k) = "range set";
    else
        statuses(k) = "needs range";
    end
end
selection = labkit.app.event.ListSelection();
if index >= 1 && index <= sourceCount
    selection = labkit.app.event.ListSelection( ...
        Ids=string(sources(index).id), Indices=index);
end
view = labkit.app.view.Snapshot() ...
    .fileItemStatuses("thermalFiles", statuses) ...
    .listSelection("thermalFiles", selection) ...
    .value("fileStatus", fileStatus(sourceCount, index, item)) ...
    .enabled("previousImage", hasItem && index > 1) ...
    .enabled("nextImage", hasItem && index < sourceCount) ...
    .value("currentImage", currentImageText(item));
end

function value = fileStatus(sourceCount, index, item)
if isempty(item)
    value = "Files: " + string(sourceCount);
    return
end
status = "needs range";
if logical(item.rangeAdjusted)
    status = "range set";
end
value = sprintf("Files: %d | Current: %d/%d | %s", ...
    sourceCount, index, sourceCount, status);
end

function value = currentImageText(item)
if isempty(item)
    value = "No FLIR image loaded";
elseif logical(item.rangeAdjusted)
    value = string(item.name) + " (range set)";
else
    value = string(item.name) + " (needs range)";
end
end

function annotation = annotationFor(annotations, sourceId)
annotation = [];
if isempty(annotations)
    return
end
match = find(string({annotations.sourceId}) == string(sourceId), 1);
if ~isempty(match)
    annotation = annotations(match);
end
end
