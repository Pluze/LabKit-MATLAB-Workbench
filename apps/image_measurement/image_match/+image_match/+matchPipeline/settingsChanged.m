function applicationState = settingsChanged(applicationState, ~, ~)
%SETTINGSCHANGED Mark unapplied settings without changing match history.
applicationState.session.workflow.pendingDirty = true;
end
