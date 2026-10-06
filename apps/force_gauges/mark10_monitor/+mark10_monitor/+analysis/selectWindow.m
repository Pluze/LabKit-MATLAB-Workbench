function applicationState = selectWindow(applicationState, event, ~)
%SELECTWINDOW Remember a row for deletion without invalidating science.
if isempty(event.CellIndices), return; end
applicationState.session.analysis.selectedWindow=event.CellIndices(1,1);
end
