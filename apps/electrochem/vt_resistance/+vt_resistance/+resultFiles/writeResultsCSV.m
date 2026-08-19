% Expected caller: VT resistance export callback and tests. Inputs are item
% structs and output filepath. Side effect is writing the stable VT CSV file.

function [ok, msg] = writeResultsCSV(items, filepath)
%WRITERESULTSCSV Write VT resistance results in legacy CSV format.

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
        T = vt_resistance.resultFiles.buildResultsTable(items);
        fprintf(fid, 'File,Ic_A,Ia_A,Vc_ss_V,Va_ss_V,Vc_baseline_V,Va_baseline_V,dVc_V,dVa_V,Rc_bc_ohm,Ra_bc_ohm,Ravg_bc_ohm,WindowMode,Detection,Status\n');
        for i = 1:height(T)
            fprintf(fid, '"%s",%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,"%s","%s","%s"\n', ...
                csvEscape(T.File{i}), ...
                T.Ic_A(i), T.Ia_A(i), T.Vc_ss_V(i), T.Va_ss_V(i), ...
                T.Vc_baseline_V(i), T.Va_baseline_V(i), T.dVc_V(i), T.dVa_V(i), ...
                T.Rc_bc_ohm(i), T.Ra_bc_ohm(i), T.Ravg_bc_ohm(i), ...
                csvEscape(T.WindowMode{i}), ...
                csvEscape(T.Detection{i}), ...
                csvEscape(T.Status{i}));
        end
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end

function s = csvEscape(x)
    s = strrep(char(x), '"', '""');
end
