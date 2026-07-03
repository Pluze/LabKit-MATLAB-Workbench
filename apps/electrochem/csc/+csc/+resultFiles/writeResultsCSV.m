% Expected caller: CSC app runner and export tests. Inputs are CV/CT item
% structs, output filepath, and CSC options. Side effect is writing the stable
% all-cycle CSC CSV file.

function [ok, msg] = writeResultsCSV(items, filepath, opts)
%WRITERESULTSCSV Write CSC all-cycle results CSV.

    if nargin < 3
        opts = struct();
    end

    ok = true;
    msg = '';

    try
        T = csc.resultFiles.buildResultsTable(items, opts);
        writetable(T, filepath);
    catch ME
        ok = false;
        msg = ME.message;
        if nargout == 0
            rethrow(ME);
        end
    end
end
