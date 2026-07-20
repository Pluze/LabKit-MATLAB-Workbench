function targets = interactionTargetAxes(obj)
% Class-folder implementation of MatlabPlatformAdapter.interactionTargetAxes.
    targets = struct("id", {}, "axes", {});
    for k = 1:numel(obj.Plan.Nodes)
        node = obj.Plan.Nodes(k);
        if node.Kind ~= "plotArea"
            continue;
        end
        for axisId = node.AxisIds
            key = labkit.app.internal.NativeAdapterValues.axisKey(node.Id, axisId);
            targetId = key;
            if numel(node.AxisIds) == 1
                targetId = node.Id;
            end
            targets(end + 1) = struct( ...
                "id", targetId, "axes", obj.Axes(char(key)));
        end
    end
end
