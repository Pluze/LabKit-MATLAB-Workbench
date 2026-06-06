% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function [timeSec, timeColumn, info] = inferTableTime(T, opts, importInfo)
%INFERTABLETIME Infer and repair the time axis for a biosignal table.
%
% Expected caller:
%   readCsvRecording.
%
% Inputs/outputs:
%   Parsed table, readRecording options, and import metadata. Returns seconds,
%   the selected time-column index or zero, and metadata describing time unit,
%   source, and repair decisions.
%
% Side effects:
%   None.

    names = T.Properties.VariableNames;
    timeColumn = 0;

    explicitColumn = optionValue(opts, 'timeColumn', []);
    if ~isempty(explicitColumn)
        timeColumn = resolveTimeColumn(names, explicitColumn);
        [timeSec, info] = convertColumnToSeconds(T.(names{timeColumn}), names{timeColumn}, opts, "explicit");
        return;
    end

    for k = 1:numel(names)
        values = T.(names{k});
        if isduration(values) || isdatetime(values)
            timeColumn = k;
            timeSec = timeToSeconds(values);
            [timeSec, repair] = repairTimeSeconds(timeSec, opts);
            info = makeTimeInfo("seconds", "datetime_or_duration", repair);
            return;
        end
    end

    for k = 1:numel(names)
        [values, isNumericColumn] = numericColumn(T.(names{k}));
        if isNumericColumn && isvector(values) && numel(values) >= 2 && ...
                isTimeLikeName(names{k})
            timeColumn = k;
            [timeSec, info] = convertColumnToSeconds(T.(names{k}), names{k}, opts, "name_inference");
            return;
        end
    end

    if numel(names) >= 2 && strcmpi(char(names{1}), 'I0')
        timeColumn = 1;
        [timeSec, info] = convertColumnToSeconds( ...
            T.(names{timeColumn}), names{timeColumn}, opts, "i0_first_column");
        return;
    end

    if ~importInfo.hasHeader
        implicitColumn = inferFirstNumericTimeColumn(T);
        if implicitColumn > 0
            timeColumn = implicitColumn;
            [timeSec, info] = convertColumnToSeconds( ...
                T.(names{timeColumn}), names{timeColumn}, opts, "headerless_first_numeric_column");
            return;
        end
    end

    implicitColumn = inferImplicitTimeColumn(T, names);
    if implicitColumn > 0
        timeColumn = implicitColumn;
        [timeSec, info] = convertColumnToSeconds( ...
            T.(names{timeColumn}), names{timeColumn}, opts, "implicit_first_column");
        return;
    end

    if optionValue(opts, 'useFirstNumericColumnAsTime', false)
        implicitColumn = inferFirstNumericTimeColumn(T);
        if implicitColumn > 0
            timeColumn = implicitColumn;
            [timeSec, info] = convertColumnToSeconds( ...
                T.(names{timeColumn}), names{timeColumn}, opts, "explicit_first_numeric_column");
            return;
        end
    end

    n = height(T);
    fallbackFs = optionValue(opts, 'fallbackFs', []);
    if ~isempty(fallbackFs) && isfinite(double(fallbackFs)) && double(fallbackFs) > 0
        timeSec = (0:n-1).' / double(fallbackFs);
        info = makeTimeInfo("sample_index_at_fallback_fs", ...
            "synthetic_sample_index", emptyTimeRepair());
    else
        timeSec = (0:n-1).';
        info = makeTimeInfo("sample_index", "synthetic_sample_index", emptyTimeRepair());
    end
end

function idx = resolveTimeColumn(names, column)
    if isnumeric(column)
        idx = column;
        if ~isscalar(idx) || idx < 1 || idx > numel(names) || idx ~= floor(idx)
            error('labkit:biosignal:InvalidTimeColumn', ...
                'Explicit time column index is out of range.');
        end
        return;
    end

    column = string(column);
    idx = find(strcmp(string(names), column), 1);
    if isempty(idx)
        idx = find(strcmpi(string(names), column), 1);
    end
    if isempty(idx)
        error('labkit:biosignal:InvalidTimeColumn', ...
            'Explicit time column was not found: %s.', column);
    end
end

function [timeSec, info] = convertColumnToSeconds(values, name, opts, source)
    if isduration(values) || isdatetime(values)
        timeSec = timeToSeconds(values);
        [timeSec, repair] = repairTimeSeconds(timeSec, opts);
        info = makeTimeInfo("seconds", source, repair);
        return;
    end
    [relativeRaw, hasPreciseRelative] = relativeNumericColumn(values);
    [raw, isNumericColumn] = numericColumn(values);
    if ~isNumericColumn
        error('labkit:biosignal:InvalidTimeColumn', ...
            'Time column must be numeric, duration, or datetime.');
    end

    raw = double(raw(:));
    if isempty(raw) || any(~isfinite(raw))
        error('labkit:biosignal:InvalidTimeColumn', ...
            'Time column contains missing or non-finite values.');
    end

    scale = unitScale(optionValue(opts, 'timeUnit', []), name);
    if hasPreciseRelative && numel(relativeRaw) == numel(raw) && all(isfinite(relativeRaw))
        raw = relativeRaw;
    else
        raw = raw - raw(1);
    end
    [timeSec, repair] = repairTimeSeconds(raw * scale, opts);
    info = makeTimeInfo(unitLabel(scale), source, repair);
end

function idx = inferImplicitTimeColumn(T, names)
    idx = 0;
    if width(T) < 2 || height(T) < 2
        return;
    end
    firstName = string(names{1});
    [firstValues, isNumericColumn] = numericColumn(T.(names{1}));
    if ~isNumericColumn || ~isvector(firstValues)
        return;
    end
    x = double(firstValues(:));
    dx = diff(x);
    if any(~isfinite(x)) || ~all(dx > 0)
        return;
    end

    clean = lower(regexprep(char(firstName), '[^a-z0-9]+', ''));
    if startsWith(clean, 'var')
        idx = 1;
        return;
    end

    if strcmp(clean, 'i0')
        idx = 1;
    end
end

function idx = inferFirstNumericTimeColumn(T)
    idx = 0;
    for k = 1:width(T)
        [values, isNumericColumn] = numericColumn(T{:, k});
        if ~isNumericColumn || ~isvector(values)
            continue;
        end
        x = double(values(:));
        if numel(x) < 2 || any(~isfinite(x))
            continue;
        end
        idx = k;
        return;
    end
end

function scale = unitScale(explicitUnit, name)
    if ~isempty(explicitUnit)
        unit = lower(string(explicitUnit));
    elseif strcmpi(char(name), 'I0')
        unit = "milliseconds";
    else
        unit = unitFromName(name);
    end

    switch unit
        case {"s", "sec", "secs", "second", "seconds"}
            scale = 1;
        case {"ms", "msec", "millisecond", "milliseconds"}
            scale = 1e-3;
        case {"us", "usec", "microsecond", "microseconds"}
            scale = 1e-6;
        case {"ns", "nsec", "nanosecond", "nanoseconds"}
            scale = 1e-9;
        case {"samples", "sample", "index", "sample_index"}
            scale = 1;
        otherwise
            scale = 1;
    end
end

function unit = unitFromName(name)
    clean = lower(regexprep(char(name), '[^a-z0-9]+', ''));
    if strcmp(clean, 'i0')
        unit = "milliseconds";
    elseif contains(clean, 'millisecond') || endsWith(clean, 'ms') || strcmp(clean, 'ms')
        unit = "milliseconds";
    elseif contains(clean, 'microsecond') || endsWith(clean, 'us') || strcmp(clean, 'us')
        unit = "microseconds";
    elseif contains(clean, 'nanosecond') || endsWith(clean, 'ns') || strcmp(clean, 'ns')
        unit = "nanoseconds";
    else
        unit = "seconds";
    end
end

function label = unitLabel(scale)
    if scale == 1
        label = "seconds";
    elseif scale == 1e-3
        label = "milliseconds";
    elseif scale == 1e-6
        label = "microseconds";
    elseif scale == 1e-9
        label = "nanoseconds";
    else
        label = "custom";
    end
end

function info = makeTimeInfo(unit, source, repair)
    info = struct('unit', string(unit), 'source', string(source), 'repair', repair);
end

function [timeSec, repair] = repairTimeSeconds(timeSec, opts)
    mode = lower(string(optionValue(opts, 'timeRepair', 'auto')));
    timeSec = double(timeSec(:));
    repair = emptyTimeRepair();
    if numel(timeSec) < 2 || mode == "none" || mode == "off"
        if ~isempty(timeSec)
            timeSec = timeSec - timeSec(1);
        end
        return;
    end

    dt = diff(timeSec);
    repair.originalNonmonotonicCount = nnz(dt <= 0);
    positiveDt = dt(isfinite(dt) & dt > 0);
    if isempty(positiveDt)
        nominalDt = fallbackDt(opts);
    else
        nominalDt = median(positiveDt);
    end
    if ~isfinite(nominalDt) || nominalDt <= 0
        nominalDt = fallbackDt(opts);
    end

    gapFactor = double(optionValue(opts, 'gapFactor', 20));
    repair.largeGapCount = nnz(positiveDt > gapFactor * nominalDt);
    repair.nominalDt = nominalDt;

    repaired = zeros(size(timeSec));
    for k = 2:numel(timeSec)
        delta = timeSec(k) - timeSec(k - 1);
        if isfinite(delta) && delta > 0
            repaired(k) = repaired(k - 1) + delta;
        else
            repaired(k) = repaired(k - 1) + nominalDt;
            repair.repairedBackwardCount = repair.repairedBackwardCount + 1;
        end
    end
    timeSec = repaired - repaired(1);
end

function dt = fallbackDt(opts)
    fallbackFs = optionValue(opts, 'fallbackFs', []);
    if ~isempty(fallbackFs) && isfinite(double(fallbackFs)) && double(fallbackFs) > 0
        dt = 1 / double(fallbackFs);
    else
        dt = 1;
    end
end

function repair = emptyTimeRepair()
    repair = struct( ...
        'originalNonmonotonicCount', 0, ...
        'repairedBackwardCount', 0, ...
        'largeGapCount', 0, ...
        'nominalDt', NaN);
end

function [values, ok] = relativeNumericColumn(raw)
    ok = false;
    values = [];
    if ~(iscell(raw) || iscategorical(raw) || isstring(raw) || ischar(raw))
        return;
    end
    try
        tokens = string(raw);
    catch
        return;
    end
    tokens = strip(tokens(:));
    tokens = erase(tokens, '"');
    if isempty(tokens) || ismissing(tokens(1)) || strlength(tokens(1)) == 0
        return;
    end

    base = tokens(1);
    values = nan(size(tokens));
    for k = 1:numel(tokens)
        token = tokens(k);
        if ismissing(token) || strlength(token) == 0
            values(k) = NaN;
        else
            values(k) = decimalTokenDiff(token, base);
        end
    end
    finiteCount = nnz(isfinite(values));
    ok = finiteCount >= max(2, ceil(0.5 * numel(values)));
end

function delta = decimalTokenDiff(token, base)
    token = char(strip(string(token)));
    base = char(strip(string(base)));
    if any(contains(token, {'e', 'E'})) || any(contains(base, {'e', 'E'}))
        delta = str2double(token) - str2double(base);
        return;
    end

    [tokenSign, tokenInt, tokenFrac, tokenOk] = splitDecimalToken(token);
    [baseSign, baseInt, baseFrac, baseOk] = splitDecimalToken(base);
    if ~tokenOk || ~baseOk
        delta = str2double(token) - str2double(base);
        return;
    end
    if tokenSign < 0 || baseSign < 0
        delta = str2double(token) - str2double(base);
        return;
    end

    fracLen = max(strlength(tokenFrac), strlength(baseFrac));
    if fracLen > 15
        delta = str2double(token) - str2double(base);
        return;
    end

    intDelta = str2double(tokenInt) - str2double(baseInt);
    tokenFrac = pad(tokenFrac, fracLen, 'right', '0');
    baseFrac = pad(baseFrac, fracLen, 'right', '0');
    if fracLen == 0
        fracDelta = 0;
    else
        fracDelta = (str2double(tokenFrac) - str2double(baseFrac)) / 10^double(fracLen);
    end
    delta = intDelta + fracDelta;
end

function [signValue, intPart, fracPart, ok] = splitDecimalToken(token)
    signValue = 1;
    intPart = "";
    fracPart = "";
    ok = false;

    token = string(token);
    if startsWith(token, "-")
        signValue = -1;
        token = extractAfter(token, 1);
    elseif startsWith(token, "+")
        token = extractAfter(token, 1);
    end
    parts = split(token, ".");
    if numel(parts) < 1 || numel(parts) > 2
        return;
    end
    intPart = parts(1);
    if strlength(intPart) == 0 || ~all(isstrprop(char(intPart), 'digit'))
        return;
    end
    if numel(parts) == 2
        fracPart = parts(2);
        if strlength(fracPart) > 0 && ~all(isstrprop(char(fracPart), 'digit'))
            return;
        end
    end
    ok = true;
end
