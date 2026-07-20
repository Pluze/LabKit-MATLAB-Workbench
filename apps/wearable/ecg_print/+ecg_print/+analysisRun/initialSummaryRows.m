% Expected caller: ecg_print.workbench.buildLayout,
% ecg_print.analysisRun.summaryRows, and direct
% unit tests. Output is a two-column cell array for the summary table. Side
% effects: none.

function rows = initialSummaryRows()
%INITIALSUMMARYROWS Return the ECG Print empty-state summary table rows.

    rows = {'Status', 'No signal analyzed'};
end
