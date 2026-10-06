function applicationState = selectResult(applicationState, event, ~)
%SELECTRESULT Highlight the exact fitted points for the selected table row.
if isempty(event.CellIndices), return; end
applicationState.session.analysis.selectedResult=event.CellIndices(1,1);
end
