% App-owned durable-state factory. Expected caller: tests and task-list
% assembly. Input is a source-id collection. Output is crop tasks with no file
% or image-processing side effects.
function tasks = tasksForSourceIds(sourceIds)
    idValues = reshape(string(sourceIds), [], 1);
    tasks = repmat(batch_crop.appState.emptyTask(), numel(idValues), 1);
    for k = 1:numel(idValues)
        tasks(k).sourceId = idValues(k);
    end
end
