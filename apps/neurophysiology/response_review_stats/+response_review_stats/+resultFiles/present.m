function view = present(state, model)
view = labkit.app.view.Snapshot().enabled("exportMetrics", ...
    height(model.metrics) > 0 && strlength(state.session.workflow.outputFolder) > 0);
end
