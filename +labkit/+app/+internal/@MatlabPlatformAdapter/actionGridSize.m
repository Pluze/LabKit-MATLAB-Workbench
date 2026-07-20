function [rows, columns] = actionGridSize(obj, node)
% Class-folder implementation of MatlabPlatformAdapter.actionGridSize.
    children = obj.nodes(node.ChildIds);
    columns = min(2, numel(children));
    labels = strings(1, numel(children));
    for k = 1:numel(children)
        labels(k) = children(k).Configuration.Label;
    end
    if any(strlength(labels) > 28)
        columns = 1;
    end
    rows = max(1, ceil(numel(children) / columns));
end
