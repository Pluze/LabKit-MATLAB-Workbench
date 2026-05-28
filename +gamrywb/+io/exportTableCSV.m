function exportTableCSV(T, filepath)
%EXPORTTABLECSV Write a table to CSV using MATLAB's default table writer.

    writetable(T, filepath);
end
