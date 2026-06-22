% App-owned state helper. Expected caller: batch-crop file chooser callback.
% Existing crop tasks are preserved for selected paths, including duplicate
% tasks for the same source image. Newly selected paths are appended as fresh
% loaded items. No file I/O occurs here.
function items = mergeChosenItems(existingItems, loadedItems)
%MERGECHOSENITEMS Preserve crop tasks while syncing the chosen source list.

    if isempty(loadedItems)
        items = repmat(batch_crop.state.emptyItem(), 0, 1);
        return;
    end
    items = repmat(batch_crop.state.emptyItem(), numel(existingItems) + numel(loadedItems), 1);
    itemCount = 0;

    existingPaths = strings(numel(existingItems), 1);
    for k = 1:numel(existingItems)
        existingPaths(k) = existingItems(k).path;
    end

    handledPaths = strings(numel(loadedItems), 1);
    handledCount = 0;
    for k = 1:numel(loadedItems)
        pathValue = loadedItems(k).path;
        if handledCount > 0 && any(handledPaths(1:handledCount) == pathValue)
            continue;
        end

        matches = existingPaths == pathValue;
        if any(matches)
            matchIndexes = find(matches);
            for matchIndex = matchIndexes(:).'
                itemCount = itemCount + 1;
                items(itemCount) = existingItems(matchIndex);
            end
        else
            itemCount = itemCount + 1;
            items(itemCount) = loadedItems(k);
        end
        handledCount = handledCount + 1;
        handledPaths(handledCount) = pathValue;
    end
    items = items(1:itemCount);
end
