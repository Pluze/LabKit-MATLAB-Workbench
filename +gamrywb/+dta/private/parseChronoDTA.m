function [meta, tables, logmsg] = parseChronoDTA(filepath)
%PARSECHRONODTA Parse Gamry chronopotentiometry-style DTA tables.

    txt = fileread(filepath);
    txt = erase(txt, char(13));
    lines = splitlines(string(txt));
    lines = cellstr(lines);

    meta = struct();
    meta.filepath = filepath;
    meta.area_cm2 = NaN;
    meta.sampleTime_s = NaN;
    meta.controlMode = "unknown";
    meta.steps = struct('idx', {}, 'I', {}, 'V', {}, 'T', {});
    tables = struct('name', {}, 'headers', {}, 'units', {}, 'data', {}, 'numericMask', {});
    logmsg = {};

    nLines = numel(lines);
    logmsg{end+1} = sprintf('Parsing DTA: %s', filepath);

    stepI = containers.Map('KeyType', 'int32', 'ValueType', 'double');
    stepV = containers.Map('KeyType', 'int32', 'ValueType', 'double');
    stepT = containers.Map('KeyType', 'int32', 'ValueType', 'double');

    for i = 1:nLines
        tok = splitTabs(lines{i});
        if numel(tok) < 3
            continue;
        end
        key = strtrim(tok{1});
        valueStr = tok{3};
        valueNum = str2double(valueStr);

        switch upper(key)
            case 'AREA'
                if isfinite(valueNum)
                    meta.area_cm2 = valueNum;
                end
            case 'SAMPLETIME'
                if isfinite(valueNum)
                    meta.sampleTime_s = valueNum;
                end
        end

        rI = regexp(key, '^ISTEP(\d+)$', 'tokens', 'once');
        if ~isempty(rI)
            idx = int32(str2double(rI{1}));
            if isfinite(valueNum)
                stepI(idx) = valueNum;
            end
        end

        rV = regexp(key, '^VSTEP(\d+)$', 'tokens', 'once');
        if ~isempty(rV)
            idx = int32(str2double(rV{1}));
            if isfinite(valueNum)
                stepV(idx) = valueNum;
            end
        end

        rT = regexp(key, '^TSTEP(\d+)$', 'tokens', 'once');
        if ~isempty(rT)
            idx = int32(str2double(rT{1}));
            if isfinite(valueNum)
                stepT(idx) = valueNum;
            end
        end
    end

    allIdx = unique([cell2mat(keys(stepI)), cell2mat(keys(stepV)), cell2mat(keys(stepT))]);
    allIdx = sort(allIdx);
    for k = 1:numel(allIdx)
        idx = allIdx(k);
        I = NaN;
        V = NaN;
        T = NaN;
        if isKey(stepI, idx)
            I = stepI(idx);
        end
        if isKey(stepV, idx)
            V = stepV(idx);
        end
        if isKey(stepT, idx)
            T = stepT(idx);
        end
        meta.steps(end+1) = struct('idx', double(idx), 'I', I, 'V', V, 'T', T); %#ok<AGROW>
    end
    meta.controlMode = inferControlMode(meta.steps);

    if ~isempty(meta.steps)
        if any(isfinite([meta.steps.I]))
            logmsg{end+1} = sprintf('Found %d ISTEP/TSTEP step(s).', numel(meta.steps));
        elseif any(isfinite([meta.steps.V]))
            logmsg{end+1} = sprintf('Found %d VSTEP/TSTEP step(s).', numel(meta.steps));
        else
            logmsg{end+1} = sprintf('Found %d step(s) with timing only.', numel(meta.steps));
        end
    else
        logmsg{end+1} = 'No ISTEP/TSTEP or VSTEP/TSTEP sequence found.';
    end

    i = 1;
    while i <= nLines
        tok = splitTabs(lines{i});
        if numel(tok) >= 3 && strcmpi(tok{2}, 'TABLE')
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
                if numel(tokj) >= 3 && strcmpi(tokj{2}, 'TABLE')
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

function mode = inferControlMode(steps)
    mode = "unknown";
    if isempty(steps)
        return;
    end

    Ivals = [steps.I];
    Vvals = [steps.V];
    if any(isfinite(Ivals))
        mode = "current";
    elseif any(isfinite(Vvals))
        mode = "voltage";
    end
end
