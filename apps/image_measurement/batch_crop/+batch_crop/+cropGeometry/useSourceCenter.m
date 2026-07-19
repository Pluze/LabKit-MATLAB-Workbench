function applicationState = useSourceCenter( ...
        applicationState, mode, callbackContext)
[applicationState, loaded] = batch_crop.sourceFiles.loadCurrent( ...
    applicationState, callbackContext);
if ~loaded
    return
end
item = batch_crop.sourceFiles.currentItem(applicationState);
center = item.centerXY;
sourceCenter = batch_crop.cropGeometry.sourceCenterXY(item.image);
if any(~isfinite(center))
    center = sourceCenter;
end
if mode == "x"
    center(1) = sourceCenter(1);
elseif mode == "y"
    center(2) = sourceCenter(2);
else
    center = sourceCenter;
end
applicationState = batch_crop.cropGeometry.setCurrentCenter( ...
    applicationState, center, true);
applicationState = batch_crop.cropGeometry.clearDerived(applicationState);
callbackContext.appendStatus("Set crop " + upper(mode) + " center.");
end
