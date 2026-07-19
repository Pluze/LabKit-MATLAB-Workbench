function state = resetImport(state, ~, ~)
state.project.results.lastAnalysis = struct(); state.project.results.lastSegmentExport = []; state.project.results.lastWaveformExport = [];
state.session.workflow.importStatus = "Import settings changed. Click Parse / refresh file.";
end
