% App-owned implementation for curvature.curveEdit.present within the curvature product workflow.
function view = present(hasImage, points, editMode)
%PRESENT Describe curve-edit availability and dynamic action text.
curveEditing = editMode == "curve";
referenceEditing = editMode == "reference";
view = labkit.app.view.Snapshot() ...
    .text("startCurveEdit", actionText(curveEditing)) ...
    .enabled("startCurveEdit", hasImage && ~referenceEditing) ...
    .enabled("undoCurvePoint", ~isempty(points) && ~referenceEditing) ...
    .enabled("clearCurve", ~isempty(points) && ~referenceEditing);
end

function value = actionText(active)
value = "Start curve edit";
if active
    value = "Finish curve edit";
end
end
