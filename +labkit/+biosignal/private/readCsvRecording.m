% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function recording = readCsvRecording(filepath, opts)
%READCSVRECORDING Read a CSV/TSV-style table into a biosignal recording.
%
% Called by:
%   labkit.biosignal.readRecording
%
% Inputs:
%   filepath - delimited text file path.
%   opts - readRecording options. Supported fields include headerLine,
%          hasHeader, timeColumn, timeUnit, signalColumns, fallbackFs,
%          timeRepair, gapFactor, and useFirstNumericColumnAsTime.
%
% Output:
%   recording - biosignal recording struct with one signal per selected
%               numeric non-time column and metadata describing header,
%               time-source, unit, and repair decisions.
%
% Errors:
%   labkit:biosignal:EmptyTable, NoSignals, InvalidTimeColumn, or
%   InvalidSignalColumns when the parsed file cannot become a recording.
%
% Notes:
%   Time inference is conservative: explicit options win, time-like names
%   and datetime/duration columns are accepted, and otherwise a synthetic
%   sample-index axis is used unless a specific opt-in rule applies.

    [T, importInfo] = readDelimitedTable(filepath, opts);
    if isempty(T)
        error('labkit:biosignal:EmptyTable', 'The input table is empty.');
    end

    names = T.Properties.VariableNames;
    [timeSec, timeColumn, timeInfo] = inferTableTime(T, opts, importInfo);
    signals = struct([]);
    signalColumns = resolveSignalColumns(names, optionValue(opts, 'signalColumns', []));
    for k = 1:numel(names)
        if k == timeColumn
            continue;
        end
        if ~isempty(signalColumns) && ~ismember(k, signalColumns)
            continue;
        end
        [values, isNumericColumn] = numericColumn(T.(names{k}));
        if ~isNumericColumn || ~isvector(values)
            continue;
        end
        sig = makeSignalStruct( ...
            string(names{k}), ...
            "table", ...
            timeSec, ...
            double(values(:)), ...
            struct('sourceKind', "table", ...
            'timeColumn', timeColumnName(names, timeColumn), ...
            'timeUnit', timeInfo.unit, ...
            'timeSource', timeInfo.source, ...
            'timeRepair', timeInfo.repair), ...
            opts);
        signals = [signals sig]; %#ok<AGROW>
    end

    recording = makeRecording(filepath, "table", signals);
    recording.metadata.timeColumn = timeColumnName(names, timeColumn);
    recording.metadata.timeUnit = timeInfo.unit;
    recording.metadata.timeSource = timeInfo.source;
    recording.metadata.timeRepair = timeInfo.repair;
    recording.metadata.importHeaderLine = importInfo.headerLine;
    recording.metadata.importHasHeader = importInfo.hasHeader;
    if isempty(recording.signals)
        error('labkit:biosignal:NoSignals', ...
            'No numeric signal columns were found in table file.');
    end
end
