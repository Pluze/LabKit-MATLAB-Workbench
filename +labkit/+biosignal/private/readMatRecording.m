% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function recording = readMatRecording(filepath, opts)
%READMATRECORDING Read timetable channels from a MAT file recording.
%
% Called by:
%   labkit.biosignal.readRecording
%
% Inputs:
%   filepath - MAT file path.
%   opts - readRecording options passed to makeSignalStruct. fallbackFs may
%          be used if a timetable time vector cannot infer fs.
%
% Output:
%   recording - biosignal recording struct containing numeric/logical vector
%               variables from every timetable variable found in the MAT
%               file. Timetable variable names become channel names.
%
% Errors:
%   labkit:biosignal:NoSignals when no numeric timetable channels are found.

    data = load(filepath);
    names = fieldnames(data);
    signals = struct([]);
    for i = 1:numel(names)
        value = data.(names{i});
        if istimetable(value)
            signals = [signals readTimetableSignals(value, names{i}, opts)]; %#ok<AGROW>
        end
    end

    recording = makeRecording(filepath, "mat", signals);
    if isempty(recording.signals)
        error('labkit:biosignal:NoSignals', ...
            'No numeric timetable channels were found in MAT file.');
    end
end

function signals = readTimetableSignals(TT, sourceName, opts)
    varNames = TT.Properties.VariableNames;
    timeSec = timeToSeconds(TT.Properties.RowTimes);
    signals = struct([]);
    for k = 1:numel(varNames)
        values = TT.(varNames{k});
        if ~(isnumeric(values) || islogical(values)) || ~isvector(values)
            continue;
        end
        sig = makeSignalStruct( ...
            string(varNames{k}), ...
            string(sourceName), ...
            timeSec, ...
            double(values(:)), ...
            struct('sourceKind', "timetable", 'sourceVariable', string(sourceName)), ...
            opts);
        signals = [signals sig]; %#ok<AGROW>
    end
end
