function applicationState = selectFile(applicationState, selection, ~)
%SELECTFILE Reset curve selection after the source list selection changes.
choices = csc.analysisRun.analysisChoices();
applicationState.session.selection.files = selection;
applicationState.session.selection.currentCurve = choices.allCycles;
end
