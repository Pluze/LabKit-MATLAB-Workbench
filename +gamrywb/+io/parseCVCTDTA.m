function [scanRate, curves, logmsg] = parseCVCTDTA(filepath)
%PARSECVCTDTA Parse Gamry CV/CT DTA scan rate and curve tables.

    txt = fileread(filepath);
    txt = erase(txt, char(13));
    lines = splitlines(string(txt));
    lines = cellstr(lines);

    scanRate = NaN;
    curves = struct('name', {}, 'headers', {}, 'units', {}, 'data', {}, 'numericMask', {});
    logmsg = {};

    nLines = numel(lines);
    logmsg{end+1} = sprintf('Total lines in file: %d', nLines);

    for i = 1:nLines
        tok = gamrywb.util.splitTabs(lines{i});
        if numel(tok) >= 3 && strcmpi(tok{1}, 'SCANRATE')
            val = str2double(tok{3});
            if ~isnan(val)
                scanRate = val / 1000;
                logmsg{end+1} = sprintf('Found SCANRATE at line %d: %.6f V/s', i, scanRate);
                break;
            end
        end
    end

    curveLines = [];
    curveNames = {};
    for i = 1:nLines
        tok = gamrywb.util.splitTabs(lines{i});
        if ~isempty(tok) && startsWith(tok{1}, 'CURVE', 'IgnoreCase', true)
            curveLines(end+1) = i; %#ok<AGROW>
            curveNames{end+1} = tok{1}; %#ok<AGROW>
        end
    end

    if isempty(curveLines)
        logmsg{end+1} = 'No CURVE line found.';
        return;
    end
    logmsg{end+1} = sprintf('Detected %d CURVE section(s).', numel(curveLines));

    for k = 1:numel(curveLines)
        i0 = curveLines(k);
        name = curveNames{k};
        logmsg{end+1} = sprintf('Parsing %s at line %d', name, i0);

        iHeader = gamrywb.util.nextNonEmpty(lines, i0 + 1);
        if isnan(iHeader)
            logmsg{end+1} = sprintf('  %s skipped: no header.', name);
            continue;
        end

        headers = gamrywb.util.splitTabs(lines{iHeader});
        if isempty(headers)
            logmsg{end+1} = sprintf('  %s skipped: empty header.', name);
            continue;
        end
        logmsg{end+1} = sprintf('  Header: %s', strjoin(headers, ', '));

        iUnits = gamrywb.util.nextNonEmpty(lines, iHeader + 1);
        if isnan(iUnits)
            logmsg{end+1} = sprintf('  %s skipped: no unit/data line.', name);
            continue;
        end

        units = gamrywb.util.splitTabs(lines{iUnits});
        iDataStart = gamrywb.util.nextNonEmpty(lines, iUnits + 1);
        if isnan(iDataStart)
            logmsg{end+1} = sprintf('  %s skipped: no data lines.', name);
            continue;
        end

        if gamrywb.util.isDataLike(units)
            logmsg{end+1} = sprintf('  No separate unit line detected; data starts at line %d.', iUnits);
            iDataStart = iUnits;
            units = repmat({''}, size(headers));
        else
            logmsg{end+1} = sprintf('  Unit line detected at %d.', iUnits);
        end

        raw = [];
        for j = iDataStart:nLines
            tok = gamrywb.util.splitTabs(lines{j});
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
                raw(end+1, :) = row; %#ok<AGROW>
            end
        end

        if isempty(raw)
            logmsg{end+1} = sprintf('  %s parsed 0 rows.', name);
            continue;
        end

        numericMask = any(~isnan(raw), 1);

        curves(end+1).name = name; %#ok<AGROW>
        curves(end).headers = headers;
        curves(end).units = units;
        curves(end).data = raw;
        curves(end).numericMask = numericMask;

        logmsg{end+1} = sprintf('  %s parsed %d rows x %d cols.', ...
            name, size(raw, 1), size(raw, 2));
    end
end
