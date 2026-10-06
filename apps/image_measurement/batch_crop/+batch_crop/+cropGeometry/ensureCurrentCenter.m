function applicationState = ensureCurrentCenter(applicationState)
if ~batch_crop.sourceFiles.hasCurrentImage(applicationState)
    return
end
item = batch_crop.sourceFiles.currentItem(applicationState);
center = item.centerXY;
if isempty(center) || any(~isfinite(center))
    center = batch_crop.cropGeometry.sourceCenterXY(item.image);
end
applicationState = batch_crop.cropGeometry.setCurrentCenter( ...
    applicationState, center, item.centerSet);
end
