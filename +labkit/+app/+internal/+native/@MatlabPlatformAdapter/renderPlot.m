function renderPlot(obj, operation)
% Class-folder implementation of MatlabPlatformAdapter.renderPlot.
    node = obj.node(operation.Target);
    renderer = node.Renderer;
    axesById = struct();
    axes = gobjects(1, numel(node.AxisIds));
    for k = 1:numel(node.AxisIds)
        axes(k) = obj.Axes(char(labkit.app.internal.native.NativeAdapterValues.axisKey(node.Id, node.AxisIds(k))));
        axesById.(char(node.AxisIds(k))) = axes(k);
    end
    viewport = labkit.app.internal.native.NativeAdapterValues.captureViewport(axes);
    value = operation.Value;
    revisionKey = "labkitAppPlotViewRevision";
    preserveViewport = all(arrayfun(@(ax) ...
        isappdata(ax, revisionKey) && ...
        isequal(getappdata(ax, revisionKey), value.ViewRevision), axes));
    renderer(axesById, value.Model);
    for k = 1:numel(axes)
        labkit.app.internal.native.enableAxesPopout(axes(k));
        setappdata(axes(k), revisionKey, value.ViewRevision);
    end
    if preserveViewport
        labkit.app.internal.native.NativeAdapterValues.restoreViewport(axes, viewport);
    end
end
