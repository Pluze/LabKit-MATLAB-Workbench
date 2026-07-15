% App-owned state adapter. Expected callers: Batch Crop presentation and
% export paths. Inputs are durable crop tasks and the parallel session image
% cache. Output is the established algorithm-facing item struct vector.
function items = workingItems(tasks, images, sources)
    if nargin < 3
        sources = struct("id", {}, "required", {}, "role", {}, ...
            "reference", {});
    end
    items = repmat(batch_crop.appState.emptyItem(), numel(tasks), 1);
    for k = 1:numel(tasks)
        taskFields = fieldnames(tasks(k));
        for fieldIndex = 1:numel(taskFields)
            name = taskFields{fieldIndex};
            if isfield(items, name)
                items(k).(name) = tasks(k).(name);
            end
        end
        items(k).path = sourcePath(tasks(k), sources);
        if k <= numel(images)
            items(k).image = images{k};
        end
    end
end

function path = sourcePath(task, sources)
    path = "";
    if ~isfield(task, 'sourceId') || isempty(sources)
        return;
    end
    match = find(string({sources.id}) == string(task.sourceId), 1, 'first');
    if ~isempty(match)
        reference = sources(match).reference;
        if isstruct(reference) && isfield(reference, 'originalPath')
            path = string(reference.originalPath);
        else
            path = string(reference);
        end
    end
end
