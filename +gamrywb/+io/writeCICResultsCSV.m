function [ok, msg] = writeCICResultsCSV(items, filepath, unitLabel)
%WRITECICRESULTSCSV Write CIC results in legacy CSV format.

    if nargin < 3
        unitLabel = 'mC/cm^2';
    end

    ok = true;
    msg = '';

    fid = fopen(filepath, 'w');
    if fid < 0
        ok = false;
        msg = 'Could not open file for writing.';
        if nargout == 0
            error(msg);
        end
        return;
    end
    cleaner = onCleanup(@() fclose(fid));

    try
        T = gamrywb.io.buildCICResultsTable(items, unitLabel);
        names = T.Properties.VariableNames;
        fprintf(fid, 'File,Amp_A,Emc_V,Ema_V,Qc_C,Qa_C,Qt_C,%s,%s,%s,Safe,Detection\n', ...
            names{8}, names{9}, names{10});
        for i = 1:height(T)
            if strcmp(T.Detection{i}, 'failed')
                fprintf(fid, '"%s",,,,,,,,,,0,"failed"\n', T.File{i});
            else
                fprintf(fid, '"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%d,"%s"\n', ...
                    T.File{i}, T.Amp_A(i), T.Emc_V(i), T.Ema_V(i), T.Qc_C(i), T.Qa_C(i), T.Qt_C(i), ...
                    T.(names{8})(i), T.(names{9})(i), T.(names{10})(i), T.Safe(i), T.Detection{i});
            end
        end
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end
