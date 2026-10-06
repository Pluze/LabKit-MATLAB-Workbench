function items = workingItems(tasks, images, sources)
%WORKINGITEMS Resolve live source paths and decoded pixels for crop tasks.
% App-local adapter for preview and export. Images follow task order; source
% IDs resolve paths without a second mutable path cache.
items = repmat(batch_crop.sourceFiles.emptyItem(), numel(tasks), 1);
paths = labkit.app.source.paths(sources);
[~, indices] = ismember(string({tasks.sourceId}), string({sources.id}));
for k = 1:numel(tasks)
    item = rmfield(tasks(k), "sourceId");
    item.path = "";
    item.image = [];
    if indices(k) > 0
        item.path = paths(indices(k));
    end
    if k <= numel(images)
        item.image = images{k};
    end
    items(k) = item;
end
end
