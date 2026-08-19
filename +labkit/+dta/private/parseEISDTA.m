% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
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
    nLines = numel(lines);
    logmsg = cell(1, nLines + 1);
    logCount = 1;
    logmsg{logCount} = sprintf('Parsing DTA: %s', filepath);

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

    [tables, tableLog] = parseTableSections(lines, 2);
    logmsg = [logmsg(1:logCount), tableLog];
end
