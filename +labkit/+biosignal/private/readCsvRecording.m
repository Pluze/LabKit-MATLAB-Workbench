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

function [timeSec, timeColumn, info] = inferTableTime(T, opts, importInfo)
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

function [T, info] = readDelimitedTable(filepath, opts)
    info = detectDelimitedLayout(filepath);
    explicitHeaderLine = optionValue(opts, 'headerLine', []);
    explicitHasHeader = optionValue(opts, 'hasHeader', []);
    if ~isempty(explicitHeaderLine)
        info.headerLine = explicitHeaderLine;
    end
    if ~isempty(explicitHasHeader)
        info.hasHeader = logical(explicitHasHeader);
    end

    if ~info.hasHeader
        T = readHeaderlessTextDelimitedTable(filepath, info);
        return;
    end

    T = readTextDelimitedTable(filepath, info);
end

function idx = resolveSignalColumns(names, columns)
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

function T = readTextDelimitedTable(filepath, info)
    lines = readlines(filepath);
    lines = erase(lines, char(13));
    headerLine = strtrim(lines(info.headerLine));
    header = trimTrailingEmptyTokens(splitDelimitedLine(headerLine));
    names = matlab.lang.makeValidName(cellstr(header));
    names = matlab.lang.makeUniqueStrings(names);

    rows = {};
    for k = info.headerLine + 1:numel(lines)
        line = strtrim(lines(k));
        if strlength(line) == 0
            continue;
        end
        tokens = splitDelimitedLine(line);
        row = repmat({''}, 1, numel(names));
        n = min(numel(tokens), numel(names));
        for j = 1:n
            row{j} = char(strip(tokens(j)));
        end
        rows(end+1, :) = row; %#ok<AGROW>
    end

    if isempty(rows)
        T = cell2table(cell(0, numel(names)), 'VariableNames', names);
    else
        T = cell2table(rows, 'VariableNames', names);
    end
end

function T = readHeaderlessTextDelimitedTable(filepath, info)
    lines = readlines(filepath);
    lines = erase(lines, char(13));
    rows = {};
    maxWidth = 0;
    for k = info.headerLine:numel(lines)
        line = strtrim(lines(k));
        if strlength(line) == 0
            continue;
        end
        tokens = splitDelimitedLine(line);
        maxWidth = max(maxWidth, numel(tokens));
        rows{end+1, 1} = tokens; %#ok<AGROW>
    end
    if isempty(rows) || maxWidth == 0
        T = table();
        return;
    end

    data = repmat({''}, numel(rows), maxWidth);
    for i = 1:numel(rows)
        tokens = rows{i};
        for j = 1:numel(tokens)
            data{i, j} = char(strip(tokens(j)));
        end
    end
    names = cellstr("Var" + string(1:maxWidth));
    T = cell2table(data, 'VariableNames', names);
end

function tokens = splitDelimitedLine(line)
    line = char(line);
    if contains(line, sprintf('\t')) && ~contains(line, ',')
        tokens = string(strsplit(line, sprintf('\t')));
        return;
    end

    tokens = strings(0, 1);
    current = "";
    inQuotes = false;
    for k = 1:numel(line)
        ch = line(k);
        if ch == '"'
            inQuotes = ~inQuotes;
            continue;
        end
        if ch == ',' && ~inQuotes
            tokens(end+1, 1) = current; %#ok<AGROW>
            current = "";
        else
            current = current + string(ch);
        end
    end
    tokens(end+1, 1) = current;
end

function tokens = trimTrailingEmptyTokens(tokens)
    while numel(tokens) > 1 && strlength(strip(tokens(end))) == 0
        tokens(end) = [];
    end
end

function info = detectDelimitedLayout(filepath)
    info = struct('headerLine', 1, 'hasHeader', true);
    lines = readlines(filepath);
    lines = erase(lines, char(13));
    maxInspect = min(numel(lines), 120);

    for k = 1:maxInspect
        line = strtrim(lines(k));
        if strlength(line) == 0
            continue;
        end

        nextLine = nextNonemptyLine(lines, k + 1, maxInspect);
        if strlength(nextLine) == 0
            continue;
        end

        if isNumericDelimitedLine(line) && isNumericDelimitedLine(nextLine)
            info.headerLine = k;
            info.hasHeader = false;
            return;
        end

        if isLikelySignalHeader(line) && isNumericDelimitedLine(nextLine)
            info.headerLine = k;
            info.hasHeader = true;
            return;
        end

        if hasMultipleDelimitedFields(line) && containsAlphabetic(line) && ...
                isNumericDelimitedLine(nextLine)
            info.headerLine = k;
            info.hasHeader = true;
            return;
        end
    end
end

function line = nextNonemptyLine(lines, startIndex, maxInspect)
    line = "";
    for k = startIndex:maxInspect
        candidate = strtrim(lines(k));
        if strlength(candidate) > 0
            line = candidate;
            return;
        end
    end
end

function tf = isNumericDelimitedLine(line)
    tokens = split(string(line), ',');
    tokens = strip(tokens);
    tokens = tokens(strlength(tokens) > 0);
    if numel(tokens) < 2
        tf = false;
        return;
    end
    values = nan(size(tokens));
    for k = 1:numel(tokens)
        if ~isempty(regexp(char(tokens(k)), '^\s*[+-]?0x[0-9a-fA-F]+\s*$', 'once'))
            tf = false;
            return;
        end
        values(k) = str2double(tokens(k));
    end
    tf = nnz(isfinite(values)) >= max(2, ceil(0.7 * numel(tokens)));
end

function tf = hasMultipleDelimitedFields(line)
    tokens = split(string(line), ',');
    tokens = strip(tokens);
    tokens = tokens(strlength(tokens) > 0);
    tf = numel(tokens) >= 2;
end

function tf = containsAlphabetic(line)
    tf = ~isempty(regexp(char(line), '[A-Za-z]', 'once'));
end

function tf = isLikelySignalHeader(line)
    tokens = split(string(line), ',');
    clean = lower(regexprep(strjoin(tokens, " "), '[^a-z0-9]+', ''));
    tf = contains(clean, 'time') || contains(clean, 'timestamp') || ...
        contains(clean, 'ecg') || contains(clean, 'lead') || ...
        contains(clean, 'rawecg') || contains(clean, 'filteredecg') || ...
        contains(clean, 'sample');
    if ~tf
        tokenClean = lower(regexprep(strip(tokens), '[^a-z0-9]+', ''));
        tf = numel(tokenClean) >= 2 && all(startsWith(tokenClean, "i"));
    end
end

function name = timeColumnName(names, timeColumn)
    if timeColumn >= 1 && timeColumn <= numel(names)
        name = string(names{timeColumn});
    else
        name = "";
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

function tf = isTimeLikeName(name)
    clean = lower(regexprep(char(name), '[^a-z0-9]+', ''));
    tf = contains(clean, 'time') || contains(clean, 'timestamp') || ...
        contains(clean, 'seconds') || contains(clean, 'millisecond') || ...
        contains(clean, 'microsecond') || contains(clean, 'nanosecond') || ...
        any(strcmp(clean, {'t', 'sec', 'secs', 'ms', 'msec', 'us', 'usec', 'ns'}));
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

function [values, ok] = numericColumn(raw)
    ok = false;
    values = [];
    if isnumeric(raw) || islogical(raw)
        values = double(raw(:));
        finiteCount = nnz(isfinite(values));
        ok = finiteCount >= max(2, ceil(0.5 * numel(values)));
        return;
    end

    if iscell(raw) || iscategorical(raw) || isstring(raw) || ischar(raw)
        try
            tokens = string(raw);
        catch
            return;
        end
        tokens = strip(tokens(:));
        tokens = erase(tokens, '"');
        values = nan(size(tokens));
        for k = 1:numel(tokens)
            token = tokens(k);
            if ismissing(token) || strlength(token) == 0
                values(k) = NaN;
            else
                values(k) = str2double(token);
            end
        end
        finiteCount = nnz(isfinite(values));
        ok = finiteCount >= max(2, ceil(0.5 * numel(values)));
    end
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
