function [meta, tables, logmsg] = parseEISDTA(filepath)
%PARSEEISDTA Parse Gamry EIS DTA metadata and numeric tables.

    txt = fileread(filepath);
    txt = erase(txt, char(13));
    lines = splitlines(string(txt));
    lines = cellstr(lines);

    meta = struct();
    meta.filepath = filepath;
    meta.tag = '';
    meta.title = '';
    meta.area_cm2 = NaN;
    tables = struct('name', {}, 'headers', {}, 'units', {}, 'data', {}, 'numericMask', {});
    logmsg = {};

    nLines = numel(lines);
    logmsg{end+1} = sprintf('Parsing DTA: %s', filepath);

    for i = 1:nLines
        tok = gamrywb.util.splitTabs(lines{i});
        if numel(tok) < 3
            continue;
        end

        key = upper(strtrim(tok{1}));
        val = tok{3};
        valNum = str2double(val);

        switch key
            case 'TAG'
                meta.tag = val;
            case 'TITLE'
                meta.title = val;
            case 'AREA'
                if isfinite(valNum)
                    meta.area_cm2 = valNum;
                end
        end
    end

    i = 1;
    while i <= nLines
        tok = gamrywb.util.splitTabs(lines{i});
        if numel(tok) >= 2 && strcmpi(tok{2}, 'TABLE')
            name = tok{1};
            iHeader = gamrywb.util.nextNonEmpty(lines, i + 1);
            iUnits = gamrywb.util.nextNonEmpty(lines, iHeader + 1);
            if isnan(iHeader) || isnan(iUnits)
                i = i + 1;
                continue;
            end

            headers = gamrywb.util.splitTabs(lines{iHeader});
            units = gamrywb.util.splitTabs(lines{iUnits});
            if gamrywb.util.isDataLike(units)
                dataStart = iUnits;
                units = repmat({''}, size(headers));
            else
                dataStart = gamrywb.util.nextNonEmpty(lines, iUnits + 1);
            end

            raw = [];
            j = dataStart;
            while j <= nLines
                tokj = gamrywb.util.splitTabs(lines{j});
                if isempty(tokj)
                    j = j + 1;
                    continue;
                end
                if numel(tokj) >= 2 && strcmpi(tokj{2}, 'TABLE')
                    break;
                end

                row = nan(1, numel(headers));
                nKeep = min(numel(tokj), numel(headers));
                anyNumeric = false;
                for c = 1:nKeep
                    v = str2double(tokj{c});
                    if ~isnan(v)
                        row(c) = v;
                        anyNumeric = true;
                    end
                end

                if anyNumeric
                    raw(end+1, :) = row; %#ok<AGROW>
                end
                j = j + 1;
            end

            if ~isempty(raw)
                numericMask = any(~isnan(raw), 1);
                tables(end+1).name = name; %#ok<AGROW>
                tables(end).headers = headers;
                tables(end).units = units;
                tables(end).data = raw;
                tables(end).numericMask = numericMask;
                logmsg{end+1} = sprintf('Table %s parsed: %d rows x %d cols.', name, size(raw, 1), size(raw, 2));
            else
                logmsg{end+1} = sprintf('Table %s found but no numeric rows.', name);
            end

            i = j;
        else
            i = i + 1;
        end
    end

    if isempty(tables)
        error('No numeric TABLE section was parsed from this DTA file.');
    end
end
