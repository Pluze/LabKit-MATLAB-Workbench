function renderPlot(obj, operation)
% Class-folder implementation of MatlabPlatformAdapter.renderPlot.
    node = obj.node(operation.Target);
    renderer = node.Renderer;
    axesById = struct();
    axes = gobjects(1, numel(node.AxisIds));
    for k = 1:numel(node.AxisIds)
        axes(k) = obj.Axes(char(labkit.app.internal.NativeAdapterValues.axisKey(node.Id, node.AxisIds(k))));
        axesById.(char(node.AxisIds(k))) = axes(k);
    end
    viewport = labkit.app.internal.NativeAdapterValues.captureViewport(axes);
    renderer(axesById, operation.Value);
    for k = 1:numel(axes)
        labkit.app.plot.enablePopout(axes(k));
    end
    labkit.app.internal.NativeAdapterValues.restoreViewport(axes, viewport);
end
