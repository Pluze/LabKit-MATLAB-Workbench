% Private DTA helper shared by the chrono and EIS parsers. Inputs are the
% already split file lines and the minimum token count for a TABLE marker.
% Outputs preserve the parsed table shape and parser log messages. The helper
% performs no file IO and assumes callers retain ownership of metadata.
function [tables, logmsg] = parseTableSections(lines, markerMinColumns)
%PARSETABLESECTIONS Parse numeric Gamry TABLE sections in source order.

% Called by:
%   parseChronoDTA, parseEISDTA

% Inputs:
%   lines - Cell array of DTA text lines without carriage returns.
%   markerMinColumns - Minimum tab-token count required before the second
%       token can identify a TABLE marker.

% Outputs:
%   tables - Struct array with name, headers, units, data, and numericMask.
%   logmsg - Cell row of one message per parsed or empty TABLE section.

% Side effects:
%   None. Throws the established parser error when no numeric table exists.

    nLines = numel(lines);
    tableCells = cell(1, nLines);
    tableCount = 0;
    logmsg = cell(1, nLines);
    logCount = 0;
    i = 1;
    while i <= nLines
        tokens = splitTabs(lines{i});
        if isTableMarker(tokens, markerMinColumns)
            name = tokens{1};
            iHeader = nextNonEmpty(lines, i + 1);
            iUnits = nextNonEmpty(lines, iHeader + 1);
            if isnan(iHeader) || isnan(iUnits)
                i = i + 1;
                continue;
            end

            headers = splitTabs(lines{iHeader});
            units = splitTabs(lines{iUnits});
            if isDataLike(units)
                dataStart = iUnits;
                units = repmat({''}, size(headers));
            else
                dataStart = nextNonEmpty(lines, iUnits + 1);
            end

            raw = nan(max(nLines - dataStart + 1, 0), numel(headers));
            rawCount = 0;
            j = dataStart;
            while j <= nLines
                rowTokens = splitTabs(lines{j});
                if isempty(rowTokens)
                    j = j + 1;
                    continue;
                end
                if isTableMarker(rowTokens, markerMinColumns)
                    break;
                end

                row = nan(1, numel(headers));
                keepCount = min(numel(rowTokens), numel(headers));
                anyNumeric = false;
                for column = 1:keepCount
                    value = str2double(rowTokens{column});
                    if ~isnan(value)
                        row(column) = value;
                        anyNumeric = true;
                    end
                end
                if anyNumeric
                    rawCount = rawCount + 1;
                    raw(rawCount, :) = row;
                end
                j = j + 1;
            end

            raw = raw(1:rawCount, :);
            logCount = logCount + 1;
            if ~isempty(raw)
                tableCount = tableCount + 1;
                tableCells{tableCount} = struct( ...
                    'name', name, ...
                    'headers', {headers}, ...
                    'units', {units}, ...
                    'data', raw, ...
                    'numericMask', any(~isnan(raw), 1));
                logmsg{logCount} = sprintf( ...
                    'Table %s parsed: %d rows x %d cols.', ...
                    name, size(raw, 1), size(raw, 2));
            else
                logmsg{logCount} = sprintf( ...
                    'Table %s found but no numeric rows.', name);
            end
            i = j;
        else
            i = i + 1;
        end
    end

    tables = [tableCells{1:tableCount}];
    logmsg = logmsg(1:logCount);
    if isempty(tables)
        error('No numeric TABLE section was parsed from this DTA file.');
    end
end

function tf = isTableMarker(tokens, markerMinColumns)
    tf = numel(tokens) >= markerMinColumns && strcmpi(tokens{2}, 'TABLE');
end
