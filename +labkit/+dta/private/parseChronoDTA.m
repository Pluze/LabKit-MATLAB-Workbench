% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function [meta, tables, logmsg] = parseChronoDTA(filepath)
%PARSECHRONODTA Parse Gamry chrono DTA metadata and TABLE sections.
%
% Called by:
%   makeChronoItem
%
% Inputs:
%   filepath - Gamry chrono DTA text file path.
%
% Outputs:
%   meta - struct with filepath, area_cm2, sampleTime_s, controlMode, and
%          steps parsed from AREA, SAMPLETIME, ISTEP/VSTEP, and TSTEP lines.
%   tables - struct array with name, headers, units, data, and numericMask.
%   logmsg - cell array of parser status messages.
%
% Notes:
%   The parser is tab-oriented and intentionally conservative; behavior is
%   guarded by DTA fixture tests and should not change without validation.

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
    nLines = numel(lines);
    logmsg = cell(1, nLines + 5);
    logCount = 1;
    logmsg{logCount} = sprintf('Parsing DTA: %s', filepath);

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
    meta.steps = repmat(struct('idx', NaN, 'I', NaN, 'V', NaN, 'T', NaN), ...
        1, numel(allIdx));
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
        meta.steps(k) = struct('idx', double(idx), 'I', I, 'V', V, 'T', T);
    end
    meta.controlMode = inferControlMode(meta.steps);

    if ~isempty(meta.steps)
        if any(isfinite([meta.steps.I]))
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('Found %d ISTEP/TSTEP step(s).', numel(meta.steps));
        elseif any(isfinite([meta.steps.V]))
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('Found %d VSTEP/TSTEP step(s).', numel(meta.steps));
        else
            logCount = logCount + 1;
            logmsg{logCount} = sprintf('Found %d step(s) with timing only.', numel(meta.steps));
        end
    else
        logCount = logCount + 1;
        logmsg{logCount} = 'No ISTEP/TSTEP or VSTEP/TSTEP sequence found.';
    end

    [tables, tableLog] = parseTableSections(lines, 3);
    logmsg = [logmsg(1:logCount), tableLog];
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
