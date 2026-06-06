% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
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
