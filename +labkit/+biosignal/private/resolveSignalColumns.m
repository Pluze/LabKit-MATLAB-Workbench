% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function idx = resolveSignalColumns(names, columns)
%RESOLVESIGNALCOLUMNS Resolve readRecording signal-column options.
%
% Expected caller:
%   readCsvRecording.
%
% Inputs/outputs:
%   Parsed table variable names and optional selected column names or indices.
%   Returns 1-based table column indices, or an empty vector for auto-detect.
%
% Side effects:
%   None. Throws labkit:biosignal:InvalidSignalColumns for invalid options.

    idx = [];
    if isempty(columns)
        return;
    end
    if isnumeric(columns)
        idx = columns(:).';
        if any(idx < 1) || any(idx > numel(names)) || any(idx ~= floor(idx))
            error('labkit:biosignal:InvalidSignalColumns', ...
                ['Signal column index is out of range. Parsed table has %d column(s): %s. ' ...
                'Use blank for auto-detection, parsed column names, or 1-based indices after header detection.'], ...
                numel(names), strjoin(string(names), ', '));
        end
        return;
    end

    if ischar(columns) || isstring(columns)
        columns = cellstr(columns);
    end
    if ~iscell(columns)
        error('labkit:biosignal:InvalidSignalColumns', ...
            'Signal columns must be names or numeric indices.');
    end

    idx = zeros(1, numel(columns));
    nameStrings = string(names);
    for k = 1:numel(columns)
        wanted = string(columns{k});
        found = find(strcmp(nameStrings, wanted), 1);
        if isempty(found)
            found = find(strcmpi(nameStrings, wanted), 1);
        end
        if isempty(found)
            error('labkit:biosignal:InvalidSignalColumns', ...
                'Signal column was not found: %s. Parsed columns: %s.', ...
                wanted, strjoin(string(names), ', '));
        end
        idx(k) = found;
    end
end
