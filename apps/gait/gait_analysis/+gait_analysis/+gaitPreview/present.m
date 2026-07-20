% App-owned implementation for gait_analysis.gaitPreview.present within the gait_analysis product workflow.
function view = present(model)
%PRESENT Supply the current model to the Gait Preview renderer.
view = labkit.app.view.Snapshot().renderPlot("gaitAxes", model);
end
