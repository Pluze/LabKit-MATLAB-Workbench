function view = present(state)
view = labkit.app.view.Snapshot().text("importStatus", string(state.session.workflow.importStatus)).enabled("previewHeader", ~isempty(state.project.inputs.sources)).enabled("refreshImport", ~isempty(state.project.inputs.sources));
end
