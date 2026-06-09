% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function [scanRate, curves, logmsg] = parseCVCTDTA(filepath)
%PARSECVCTDTA Parse Gamry CV/CT DTA scan rate and CURVE sections.
%
% Called by:
%   labkit.dta.loadFile through its private CV/CT item builder.
%
% Inputs:
%   filepath - Gamry CV/CT DTA text file path.
%
% Outputs:
%   scanRate - SCANRATE converted from mV/s to V/s, or NaN if absent.
%   curves - struct array with name, headers, units, data, and numericMask.
%   logmsg - cell array of parser status messages.
%
% Notes:
%   This parser preserves section order and keeps numeric masks so the public
%   facade can expose parsed curve data without app code reading raw text.

    txt = fileread(filepath);
    txt = erase(txt, char(13));
    lines = splitlines(string(txt));
    lines = cellstr(lines);

    scanRate = NaN;
    nLines = numel(lines);
    curves = struct('name', {}, 'headers', {}, 'units', {}, 'data', {}, 'numericMask', {});
    logmsg = cell(max(4 * nLines + 4, 1), 1);
    logCount = 1;
    logmsg{logCount} = sprintf('Total lines in file: %d', nLines);

    for i = 1:nLines
        tok = splitTabs(lines{i});
        if numel(tok) >= 3 && strcmpi(tok{1}, 'SCANRATE')
            val = str2double(tok{3});
            if ~isnan(val)
                scanRate = val / 1000;
                logCount = logCount + 1;
                logmsg{logCount} = sprintf('Found SCANRATE at line %d: %.6f V/s', i, scanRate);
                break;
            end
        end
    end

    curveLines = zeros(nLines, 1);
    curveNames = cell(nLines, 1);
    curveCount = 0;
    for i = 1:nLines
        tok = splitTabs(lines{i});
        if ~isempty(tok) && startsWith(tok{1}, 'CURVE', 'IgnoreCase', true)
            curveCount = curveCount + 1;
            curveLines(curveCount) = i;
            curveNames{curveCount} = tok{1};
        end
    end
    curveLines = curveLines(1:curveCount);
    curveNames = curveNames(1:curveCount);

    if isempty(curveLines)
        logCount = logCount + 1;
        logmsg{logCount} = 'No CURVE line found.';
        logmsg = logmsg(1:logCount);
        return;
    end
    logCount = logCount + 1;
    logmsg{logCount} = sprintf('Detected %d CURVE section(s).', numel(curveLines));

    parsedCurves = repmat(curves, 1, numel(curveLines));
    parsedCount = 0;
    for k = 1:numel(curveLines)
        i0 = curveLines(k);
        name = curveNames{k};
        logCount = logCount + 1;
        logmsg{logCount} = sprintf('Parsing %s at line %d', name, i0);

        iHeader = nextNonEmpty(lines, i0 + 1);
        if isnan(iHeader)
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('  %s skipped: no header.', name);
            continue;
        end

        headers = splitTabs(lines{iHeader});
        if isempty(headers)
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('  %s skipped: empty header.', name);
            continue;
        end
        logCount = logCount + 1;
        logmsg{logCount} = sprintf('  Header: %s', strjoin(headers, ', '));

        iUnits = nextNonEmpty(lines, iHeader + 1);
        if isnan(iUnits)
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('  %s skipped: no unit/data line.', name);
            continue;
        end

        units = splitTabs(lines{iUnits});
        iDataStart = nextNonEmpty(lines, iUnits + 1);
        if isnan(iDataStart)
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('  %s skipped: no data lines.', name);
            continue;
        end

        if isDataLike(units)
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('  No separate unit line detected; data starts at line %d.', iUnits);
            iDataStart = iUnits;
            units = repmat({''}, size(headers));
        else
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('  Unit line detected at %d.', iUnits);
        end

        raw = nan(nLines - iDataStart + 1, numel(headers));
        rawCount = 0;
        for j = iDataStart:nLines
            tok = splitTabs(lines{j});
            if isempty(tok)
                continue;
            end
            if startsWith(tok{1}, 'CURVE', 'IgnoreCase', true)
                break;
            end

            row = nan(1, numel(headers));
            nKeep = min(numel(tok), numel(headers));
            anyNumeric = false;
            for c = 1:nKeep
                v = str2double(tok{c});
                if ~isnan(v)
                    row(c) = v;
                    anyNumeric = true;
                end
            end
            if anyNumeric
                rawCount = rawCount + 1;
                raw(rawCount, :) = row;
            end
        end
        raw = raw(1:rawCount, :);

        if isempty(raw)
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('  %s parsed 0 rows.', name);
            continue;
        end

        numericMask = any(~isnan(raw), 1);

        parsedCount = parsedCount + 1;
        parsedCurves(parsedCount).name = name;
        parsedCurves(parsedCount).headers = headers;
        parsedCurves(parsedCount).units = units;
        parsedCurves(parsedCount).data = raw;
        parsedCurves(parsedCount).numericMask = numericMask;

        logCount = logCount + 1;
        logmsg{logCount} = sprintf('  %s parsed %d rows x %d cols.', ...
            name, size(raw, 1), size(raw, 2));
    end

    curves = parsedCurves(1:parsedCount);
    logmsg = logmsg(1:logCount);
end
