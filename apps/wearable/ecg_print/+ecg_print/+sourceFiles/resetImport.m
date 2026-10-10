function applicationState = resetImport(applicationState, ~, ~)
%RESETIMPORT Require a fresh parse after import settings change.
applicationState = ecg_print.analysisRun.clearAnalysis(applicationState);
applicationState.session.importDirty = true;
applicationState.session.workflow.importStatus = "Import settings changed. Select Parse / refresh file.";
applicationState.session.analysisStatus = "Refresh the file to apply import settings.";
end
