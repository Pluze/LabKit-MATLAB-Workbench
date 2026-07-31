function targets = interactionTargetAxes(obj)
% Class-folder implementation of MatlabPlatformAdapter.interactionTargetAxes.
    capacity = sum(arrayfun(@(node) numel(node.AxisIds), obj.Plan.Nodes));
    targets = repmat(struct("id", "", "axes", []), 1, capacity);
    targetCount = 0;
    for k = 1:numel(obj.Plan.Nodes)
        node = obj.Plan.Nodes(k);
        if node.Kind ~= "plotArea"
            continue;
        end
        for axisId = node.AxisIds
            key = labkit.app.internal.NativeAdapterValues.axisKey(node.Id, axisId);
            targetId = key;
            if isscalar(node.AxisIds)
                targetId = node.Id;
            end
            targetCount = targetCount + 1;
            targets(targetCount) = struct( ...
                "id", targetId, "axes", obj.Axes(char(key)));
        end
    end
    targets = targets(1:targetCount);
end
