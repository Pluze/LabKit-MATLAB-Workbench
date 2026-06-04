function name = timeColumnName(names, timeColumn)
%TIMECOLUMNNAME Return the selected time column name for metadata.
%
% Expected caller:
%   readCsvRecording.
%
% Inputs/outputs:
%   Parsed table names and a 1-based time-column index. Returns an empty
%   string when no table column was used for time.
%
% Side effects:
%   None.

    if timeColumn >= 1 && timeColumn <= numel(names)
        name = string(names{timeColumn});
    else
        name = "";
    end
end
