function [meta, tables, logmsg] = parseEISDTA(filepath)
%PARSEEISDTA Parse Gamry EIS DTA metadata and ZCURVE/TABLE sections.
%
% Called by:
%   makeEISItem
%
% Inputs:
%   filepath - Gamry EIS DTA text file path.
%
% Outputs:
%   meta - struct with filepath, tag, title, and area_cm2.
%   tables - struct array with name, headers, units, data, and numericMask.
%   logmsg - cell array of parser status messages.
%
% Notes:
%   This private parser owns raw DTA text interpretation. Apps should access
%   parsed EIS values through labkit.dta.getZCurve/getCurveXY.

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
        tok = splitTabs(lines{i});
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
        tok = splitTabs(lines{i});
        if numel(tok) >= 2 && strcmpi(tok{2}, 'TABLE')
            name = tok{1};
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

            raw = [];
            j = dataStart;
            while j <= nLines
                tokj = splitTabs(lines{j});
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
