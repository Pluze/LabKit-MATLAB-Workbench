% Private biosignal helper. Expected caller: the readRecording import plan.
% Inputs are a MAT path and public import options. Output is a normalized
% recording built from ordinary table variables. Side effects: file reads only.
function recording = readTableMatRecording(filepath, opts)
%READTABLEMATRECORDING Decode numeric channels from MAT table variables.

    data = load(filepath);
    names = fieldnames(data);
    chunks = cell(1, numel(names));
    chunkCount = 0;
    for k = 1:numel(names)
        value = data.(names{k});
        if istable(value) && ~istimetable(value)
            signals = tableSignals(value, string(names{k}), opts);
            if ~isempty(signals)
                chunkCount = chunkCount + 1;
                chunks{chunkCount} = signals;
            end
        end
    end
    chunks = chunks(1:chunkCount);
    signals = struct([]);
    if ~isempty(chunks)
        signals = [chunks{:}];
    end
    recording = makeRecording(filepath, "mat", signals);
    recording.metadata.sourceKind = "table_mat";
    if isempty(recording.signals)
        error('labkit:biosignal:NoSignals', ...
            'No numeric channels were found in MAT table variables.');
    end
end

function signals = tableSignals(T, sourceName, opts)
    names = T.Properties.VariableNames;
    importInfo = struct('hasHeader', true);
    [timeSec, timeColumn, timeInfo] = inferTableTime(T, opts, importInfo);
    selected = resolveSignalColumns(names, optionValue(opts, 'signalColumns', []));
    signalCells = cell(1, numel(names));
    signalCount = 0;
    for k = 1:numel(names)
        if k == timeColumn || (~isempty(selected) && ~ismember(k, selected))
            continue;
        end
        [values, isNumericColumn] = numericColumn(T.(names{k}));
        if ~isNumericColumn || ~isvector(values)
            continue;
        end
        metadata = struct( ...
            'sourceKind', "table_mat", ...
            'sourceVariable', sourceName, ...
            'timeColumn', timeColumnName(names, timeColumn), ...
            'timeUnit', timeInfo.unit, ...
            'timeSource', timeInfo.source, ...
            'timeRepair', timeInfo.repair);
        signalCount = signalCount + 1;
        signalCells{signalCount} = makeSignalStruct( ...
            string(names{k}), sourceName, timeSec, double(values(:)), metadata, opts);
        signalCells{signalCount}.unit = tableVariableUnit(T, k);
    end
    signals = struct([]);
    if signalCount > 0
        signals = [signalCells{1:signalCount}];
    end
end

function unit = tableVariableUnit(T, column)
    unit = "";
    units = T.Properties.VariableUnits;
    if numel(units) >= column && ~isempty(units{column})
        unit = string(units{column});
    end
end
