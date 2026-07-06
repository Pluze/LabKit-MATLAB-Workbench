% Expected caller: CSC app action handlers. Inputs are loaded CSC items,
% framework UI/services data, and export options. Side effect is prompting for
% a CSV path and writing the minimal CV point-level data CSV.

function [ok, msg, cancelled] = promptExportVoltageCurrent(items, services, opts)
%PROMPTEXPORTVOLTAGECURRENT Prompt for and write CV data CSV.

    ok = false;
    msg = '';
    cancelled = false;

    if isempty(items)
        labkit.ui.runtime.showAlert(services.figure, ...
            'No voltage/current data to export.', 'Export');
        return;
    end

    [out, cancelled] = labkit.ui.runtime.promptOutputFile( ...
        'csc_cv_data.csv', 'Export CV data CSV', 'csc_cv_data.csv');
    if cancelled
        return;
    end

    [ok, msg, info] = csc.resultFiles.writeVoltageCurrentCSV(items, out, opts);
    if ~ok
        labkit.ui.runtime.showAlert(services.figure, msg, 'Export');
        return;
    end
    if numel(info.files) == 1
        msg = sprintf('Exported CV data CSV: %s (%d voltage rows)', ...
            char(info.files(1)), info.rows);
    else
        folder = fileparts(char(info.files(1)));
        msg = sprintf('Exported %d CV data CSV files in %s (%d voltage rows)', ...
            numel(info.files), folder, info.rows);
    end
end
