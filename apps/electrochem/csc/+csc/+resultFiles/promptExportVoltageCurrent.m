% Expected caller: CSC app action handlers. Inputs are loaded CSC items,
% framework UI/services data, and export options. Side effect is prompting for
% a CSV path and writing the minimal CV point-level data CSV.

function [ok, msg, cancelled] = promptExportVoltageCurrent(items, services, opts)
%PROMPTEXPORTVOLTAGECURRENT Prompt for and write CV data CSV.

    ok = false;
    msg = '';
    cancelled = false;

    if isempty(items)
        labkit.ui.app.showAlert(services.figure, ...
            'No voltage/current data to export.', 'Export');
        return;
    end

    [out, cancelled] = labkit.ui.app.promptOutputFile( ...
        'csc_cv_data.csv', 'Export CV data CSV', 'csc_cv_data.csv');
    if cancelled
        return;
    end

    [ok, msg, info] = csc.resultFiles.writeVoltageCurrentCSV(items, out, opts);
    if ~ok
        labkit.ui.app.showAlert(services.figure, msg, 'Export');
        return;
    end
    msg = sprintf('Exported CV data CSV: %s (%d point rows)', ...
        char(info.files(1)), info.rows);
end
