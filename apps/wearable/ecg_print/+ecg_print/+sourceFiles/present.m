% App-owned implementation for ecg_print.sourceFiles.present within the ecg_print product workflow.
function view = present(state)
view = labkit.app.view.Snapshot().text("importStatus", string(state.session.workflow.importStatus)).enabled("previewHeader", ~isempty(state.project.inputs.sources)).enabled("refreshImport", ~isempty(state.project.inputs.sources));
end
