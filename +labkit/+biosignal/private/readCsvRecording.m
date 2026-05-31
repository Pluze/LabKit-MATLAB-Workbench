function recording = readCsvRecording(filepath, opts)
%READCSVRECORDING Read numeric columns from a delimited text table.

    T = readtable(filepath, 'VariableNamingRule', 'preserve');
    if isempty(T)
        error('labkit:biosignal:EmptyTable', 'The input table is empty.');
    end

    names = T.Properties.VariableNames;
    [timeSec, timeColumn] = inferTableTime(T);
    signals = struct([]);
    for k = 1:numel(names)
        if k == timeColumn
            continue;
        end
        values = T.(names{k});
        if ~(isnumeric(values) || islogical(values)) || ~isvector(values)
            continue;
        end
        sig = makeSignalStruct( ...
            string(names{k}), ...
            "table", ...
            timeSec, ...
            double(values(:)), ...
            struct('sourceKind', "table", 'timeColumn', timeColumnName(names, timeColumn)), ...
            opts);
        signals = [signals sig]; %#ok<AGROW>
    end

    recording = makeRecording(filepath, "table", signals);
    if isempty(recording.signals)
        error('labkit:biosignal:NoSignals', ...
            'No numeric signal columns were found in table file.');
    end
end

function [timeSec, timeColumn] = inferTableTime(T)
    names = T.Properties.VariableNames;
    timeColumn = 0;
    for k = 1:numel(names)
        values = T.(names{k});
        if isduration(values) || isdatetime(values)
            timeColumn = k;
            timeSec = timeToSeconds(values);
            return;
        end
        if isnumeric(values) && isvector(values) && numel(values) >= 2
            x = double(values(:));
            dx = diff(x);
            if all(isfinite(x)) && all(dx > 0)
                timeColumn = k;
                timeSec = x - x(1);
                return;
            end
        end
    end

    n = height(T);
    timeSec = (0:n-1).';
end

function name = timeColumnName(names, timeColumn)
    if timeColumn >= 1 && timeColumn <= numel(names)
        name = string(names{timeColumn});
    else
        name = "";
    end
end
