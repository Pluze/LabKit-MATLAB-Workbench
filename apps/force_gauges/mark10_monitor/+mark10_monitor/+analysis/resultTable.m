function value = resultTable(rows)
%RESULTTABLE Convert internal result rows into an export-ready table.
names = {'Segment', 'Phase', 'Start_s', 'End_s', 'FitStart_mm', ...
    'FitEnd_mm', 'Points', 'Stiffness_N_per_mm', 'YoungsModulus_MPa', ...
    'R_squared', 'Status'};
if isempty(rows)
    value = cell2table(cell(0, numel(names)), 'VariableNames', names);
else
    value = cell2table(rows, 'VariableNames', names);
end
end
