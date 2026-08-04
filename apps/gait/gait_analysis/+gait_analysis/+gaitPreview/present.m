% App-owned implementation for gait_analysis.gaitPreview.present within the gait_analysis product workflow.
function view = present(model, viewRevision)
%PRESENT Supply one model and viewport revision to both preview rows.
view = labkit.app.view.Snapshot() ...
    .renderPlot("gaitStepAxes", model, ViewRevision=viewRevision) ...
    .renderPlot("gaitContextAxes", model, ViewRevision=viewRevision);
end
