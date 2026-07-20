% App-owned implementation for curvature.curveEdit.toggle within the curvature product workflow.
function applicationState = toggle(applicationState, callbackContext)
%TOGGLE Enter or leave managed curve-anchor editing.
if isempty(applicationState.session.cache.image)
    callbackContext.alert( ...
        "Open an image before editing curve points.", "No image loaded");
    return
end
if string(applicationState.session.workflow.editMode) == "curve"
    applicationState.session.workflow.editMode = "none";
    callbackContext.appendStatus("Finished curve edit.");
else
    applicationState.session.workflow.editMode = "curve";
    applicationState.session.view.scaleBar = [];
    applicationState = ...
        curvature.curveEdit.clearMeasurements(applicationState);
    callbackContext.appendStatus( ...
        "Started curve edit. Double-click blank image space to add or " + ...
        "insert points; drag points to move; double-click a point to delete.");
end
end
