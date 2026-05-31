function recording = readMatRecording(filepath, opts)
%READMATRECORDING Read numeric timetable channels from a MAT file.

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
