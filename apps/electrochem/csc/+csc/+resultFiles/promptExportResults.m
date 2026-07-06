% Expected caller: CSC app action handlers. Inputs are loaded CSC items,
% framework UI/services data, and export options. Side effect is prompting for
% a CSV path and writing the all-cycle CSC result CSV.

function [ok, msg, cancelled] = promptExportResults(items, services, opts)
%PROMPTEXPORTRESULTS Prompt for and write the CSC results CSV.

    ok = false;
    msg = '';
    cancelled = false;

    if isempty(items)
        labkit.ui.runtime.showAlert(services.figure, ...
            'No results to export.', 'Export');
        return;
    end

    [out, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        'csc_all_cycles.csv', 'Save all-cycle CSC CSV', ...
        'csc_all_cycles.csv');
    if cancelled
        return;
    end

    [ok, msg] = csc.resultFiles.writeResultsCSV(items, out, opts);
    if ~ok
        labkit.ui.runtime.showAlert(services.figure, msg, 'Export');
        return;
    end
    msg = ['Exported CSC CSV: ' char(out)];
end
