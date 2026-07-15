% App-owned task/source reconciliation. Expected caller: Batch Crop file
% selection. Inputs are existing durable tasks/sources, parallel cached images,
% selected paths, and the runtime source-record factory. Outputs preserve
% duplicate crop tasks for retained sources and append one fresh task per new
% source without performing image I/O.
function [tasks, sources, images] = reconcileSelectedSources( ...
        existingTasks, existingSources, existingImages, paths, sourceRecord)
    tasks = repmat(batch_crop.appState.emptyTask(), 0, 1);
    sources = emptySources();
    images = cell(0, 1);
    paths = unique(string(paths), 'stable');
    for k = 1:numel(paths)
        sourceIndex = find(sourcePaths(existingSources) == paths(k), ...
            1, 'first');
        if isempty(sourceIndex)
            sourceId = nextSourceId(existingSources, sources);
            source = sourceRecord(sourceId, "cropSource", paths(k), true);
            matchingTasks = [];
        else
            source = existingSources(sourceIndex);
            sourceId = string(source.id);
            matchingTasks = find(string({existingTasks.sourceId}) == sourceId);
        end
        sources(end + 1) = source;
        if isempty(matchingTasks)
            task = batch_crop.appState.emptyTask();
            task.sourceId = sourceId;
            tasks(end + 1, 1) = task;
            images{end + 1, 1} = [];
        else
            for taskIndex = matchingTasks(:).'
                tasks(end + 1, 1) = existingTasks(taskIndex);
                if taskIndex <= numel(existingImages)
                    images{end + 1, 1} = existingImages{taskIndex};
                else
                    images{end + 1, 1} = [];
                end
            end
        end
    end
end

function sourceId = nextSourceId(existingSources, newSources)
    ids = [string({existingSources.id}), string({newSources.id})];
    number = numel(ids) + 1;
    sourceId = "image" + string(number);
    while any(ids == sourceId)
        number = number + 1;
        sourceId = "image" + string(number);
    end
end

function paths = sourcePaths(sources)
    paths = strings(numel(sources), 1);
    for k = 1:numel(sources)
        reference = sources(k).reference;
        if isstruct(reference) && isfield(reference, 'originalPath')
            paths(k) = string(reference.originalPath);
        else
            paths(k) = string(reference);
        end
    end
end

function sources = emptySources()
    sources = struct("id", {}, "required", {}, "role", {}, ...
        "reference", {});
end
