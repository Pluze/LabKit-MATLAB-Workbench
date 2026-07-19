function applicationState = clearDerived(applicationState, clearCanvas)
if nargin < 2
    clearCanvas = false;
end
applicationState.project.results = ...
    batch_crop.resultFiles.clearExportState(applicationState.project.results);
if clearCanvas
    applicationState.session.cache.canvas = ...
        batch_crop.cropGeometry.emptyCanvasCache();
end
end
