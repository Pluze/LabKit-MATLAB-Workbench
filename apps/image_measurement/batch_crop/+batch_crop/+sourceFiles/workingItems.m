% App-owned source/task adapter. Expected callers: Batch Crop presentation and
% export paths. Inputs are durable crop tasks and the parallel session image
% cache. Output is the established algorithm-facing item struct vector.
function items = workingItems(tasks, images, paths)
    if nargin < 3
        paths = strings(numel(tasks), 1);
    end
    items = repmat(batch_crop.sourceFiles.emptyItem(), numel(tasks), 1);
    for k = 1:numel(tasks)
        taskFields = fieldnames(tasks(k));
        for fieldIndex = 1:numel(taskFields)
            name = taskFields{fieldIndex};
            if isfield(items, name)
                items(k).(name) = tasks(k).(name);
            end
        end
        if k <= numel(paths)
            items(k).path = string(paths(k));
        end
        if k <= numel(images)
            items(k).image = images{k};
        end
    end
end
