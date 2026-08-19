% Private biosignal helper. Expected caller: labkit.biosignal facade and
% internal import/recording pipeline. Inputs and outputs use internal signal,
% recording, time, or option values. Side effects: file reads only in importer
% helpers; assumes public callers own workflow validation and user-facing errors.
function [T, info] = readDelimitedTable(filepath, opts)
%READDELIMITEDTABLE Read and normalize a delimited biosignal text table.
%
% Expected caller:
%   readCsvRecording.
%
% Inputs/outputs:
%   File path plus readRecording import options. Returns a MATLAB table and
%   import metadata with header line and has-header decisions.
%
% Side effects:
%   Reads the input file only. Does not construct recordings or signals.

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

function T = readTextDelimitedTable(filepath, info)
    lines = readlines(filepath);
    lines = erase(lines, char(13));
    headerLine = strtrim(lines(info.headerLine));
    header = trimTrailingEmptyTokens(splitDelimitedLine(headerLine));
    names = matlab.lang.makeValidName(cellstr(header));
    names = matlab.lang.makeUniqueStrings(names);
    skipNonDataRows = isLikelySignalHeader(headerLine) || ...
        isTimeLikeName(firstToken(header));

    rows = cell(numel(lines) - info.headerLine, numel(names));
    rowCount = 0;
    for k = info.headerLine + 1:numel(lines)
        line = strtrim(lines(k));
        if strlength(line) == 0
            continue;
        end
        tokens = splitDelimitedLine(line);
        first = firstToken(tokens);
        if skipNonDataRows && ~isDecimalDataToken(first) && ...
                ~isExplicitMissingNumericToken(first)
            continue;
        end
        row = repmat({''}, 1, numel(names));
        n = min(numel(tokens), numel(names));
        for j = 1:n
            row{j} = char(strip(tokens(j)));
        end
        rowCount = rowCount + 1;
        rows(rowCount, :) = row;
    end
    rows = rows(1:rowCount, :);

    if isempty(rows)
        T = cell2table(cell(0, numel(names)), 'VariableNames', names);
    else
        T = cell2table(rows, 'VariableNames', names);
    end
end

function T = readHeaderlessTextDelimitedTable(filepath, info)
    lines = readlines(filepath);
    lines = erase(lines, char(13));
    rows = cell(numel(lines) - info.headerLine + 1, 1);
    rowCount = 0;
    maxWidth = 0;
    for k = info.headerLine:numel(lines)
        line = strtrim(lines(k));
        if strlength(line) == 0
            continue;
        end
        tokens = splitDelimitedLine(line);
        maxWidth = max(maxWidth, numel(tokens));
        rowCount = rowCount + 1;
        rows{rowCount, 1} = tokens;
    end
    rows = rows(1:rowCount);
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

    tokens = strings(numel(line) + 1, 1);
    tokenCount = 0;
    current = "";
    inQuotes = false;
    for k = 1:numel(line)
        ch = line(k);
        if ch == '"'
            inQuotes = ~inQuotes;
            continue;
        end
        if ch == ',' && ~inQuotes
            tokenCount = tokenCount + 1;
            tokens(tokenCount, 1) = current;
            current = "";
        else
            current = current + string(ch);
        end
    end
    tokenCount = tokenCount + 1;
    tokens(tokenCount, 1) = current;
    tokens = tokens(1:tokenCount);
end

function tokens = trimTrailingEmptyTokens(tokens)
    while numel(tokens) > 1 && strlength(strip(tokens(end))) == 0
        tokens(end) = [];
    end
end

function info = detectDelimitedLayout(filepath)
    info = struct('headerLine', 1, 'hasHeader', true, ...
        'biopacChannelNames', strings(0, 1), ...
        'biopacChannelUnits', strings(0, 1));
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
            info = detectBiopacTextMetadata(lines, info);
            return;
        end

        if isLikelySignalHeader(line) && isNumericDelimitedLine(nextLine)
            info.headerLine = k;
            info.hasHeader = true;
            info = detectBiopacTextMetadata(lines, info);
            return;
        end

        if hasMultipleDelimitedFields(line) && containsAlphabetic(line) && ...
                isNumericDelimitedLine(nextLine)
            info.headerLine = k;
            info.hasHeader = true;
            info = detectBiopacTextMetadata(lines, info);
            return;
        end
    end
    info = detectBiopacTextMetadata(lines, info);
end

function info = detectBiopacTextMetadata(lines, info)
    if ~info.hasHeader || info.headerLine < 4
        return;
    end
    channelLine = 0;
    channelCount = 0;
    for k = 1:info.headerLine - 1
        match = regexp(char(strtrim(lines(k))), ...
            '^([0-9]+)\s+channels?$', 'tokens', 'once', 'ignorecase');
        if ~isempty(match)
            channelLine = k;
            channelCount = str2double(match{1});
            break;
        end
    end
    if channelLine == 0 || channelCount < 1 || ...
            channelLine + 2 * channelCount >= info.headerLine + 1
        return;
    end

    header = trimTrailingEmptyTokens(splitDelimitedLine(strtrim(lines(info.headerLine))));
    if numel(header) ~= channelCount + 1 || ~isTimeLikeName(firstToken(header))
        return;
    end
    names = strings(channelCount, 1);
    units = strings(channelCount, 1);
    for k = 1:channelCount
        names(k) = strtrim(lines(channelLine + 2 * k - 1));
        units(k) = strtrim(lines(channelLine + 2 * k));
    end
    if any(strlength(names) == 0)
        return;
    end
    info.biopacChannelNames = names;
    info.biopacChannelUnits = units;
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

function token = firstToken(tokens)
    token = "";
    if ~isempty(tokens)
        token = strip(tokens(1));
    end
end

function tf = isDecimalDataToken(token)
    token = char(strip(string(token)));
    if isempty(token)
        tf = false;
        return;
    end
    if ~isempty(regexp(token, '^\s*[+-]?0x[0-9a-fA-F]+\s*$', 'once'))
        tf = false;
        return;
    end
    value = str2double(token);
    tf = isfinite(value);
end

function tf = isExplicitMissingNumericToken(token)
    clean = strtrim(char(string(token)));
    tf = any(strcmpi(clean, {'nan', '+nan', '-nan', 'inf', '+inf', '-inf', ...
        'na', 'missing'}));
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
    clean = regexprep(lower(strjoin(tokens, " ")), '[^a-z0-9]+', '');
    tf = contains(clean, 'time') || contains(clean, 'timestamp') || ...
        contains(clean, 'ecg') || contains(clean, 'lead') || ...
        contains(clean, 'rawecg') || contains(clean, 'filteredecg') || ...
        contains(clean, 'sample');
    if ~tf
        tokenClean = regexprep(lower(strip(tokens)), '[^a-z0-9]+', '');
        tf = numel(tokenClean) >= 2 && all(startsWith(tokenClean, "i"));
    end
end
